import re
import os
import shutil
from markdownify import markdownify as md
from bs4 import BeautifulSoup

SQL_FILE = "jgaitpro_wpblog.sql"
UPLOADS_DIR = "uploads"
CONTENT_DIR = os.path.join("content", "posts")
STATIC_UPLOADS_DIR = os.path.join("static", "uploads")

with open(SQL_FILE, "r", encoding="utf-8", errors="ignore") as f:
    sql_data = f.read()

def extract_insert(table):
    m = re.search(rf"INSERT INTO `{table}` .*? VALUES\s*(.*?);\n/\*!\d+", sql_data, re.S)
    return m.group(1) if m else None

posts_seg = extract_insert("wp_posts")
terms_seg = extract_insert("wp_terms")
tax_seg = extract_insert("wp_term_taxonomy")
rel_seg = extract_insert("wp_term_relationships")
users_seg = extract_insert("wp_users")
meta_seg = extract_insert("wp_postmeta")

if not posts_seg:
    print("No se encontró wp_posts")
    exit()

def split_tuples(s):
    tuples=[]; depth=0; ins=False; esc=False; start=None
    for i,ch in enumerate(s):
        if ins:
            if esc: esc=False
            elif ch=="\\": esc=True
            elif ch=="'": ins=False
        else:
            if ch=="'": ins=True
            elif ch=="(":
                if depth==0: start=i
                depth+=1
            elif ch==")":
                depth-=1
                if depth==0 and start is not None: tuples.append(s[start:i+1])
    return tuples

def split_fields(t):
    s=t[1:-1]
    arr=[]; cur=[]; ins=False; esc=False
    for ch in s:
        if ins:
            cur.append(ch)
            if esc: esc=False
            elif ch=="\\": esc=True
            elif ch=="'": ins=False
        else:
            if ch=="'":
                ins=True; cur.append(ch)
            elif ch==",":
                arr.append("".join(cur).strip()); cur=[]
            else:
                cur.append(ch)
    arr.append("".join(cur).strip())
    return arr

def dec(v):
    v=v.strip()
    if v=="NULL": return ""
    if v.startswith("'") and v.endswith("'"):
        v=v[1:-1]
        v=v.replace("\\r\\n","\n").replace("\\n","\n").replace("\\'","'").replace('\\\"','"')
    return v

def slugify(s):
    s=re.sub(r'https?://\S+','',s)
    s=re.sub(r'[^a-zA-Z0-9]+','-',s).strip('-').lower()
    return s[:90] if s else "post"

terms={}
taxonomies={}
relationships={}
users={}
thumbnail_map={}
attached_files={}
posts_lookup={}

if terms_seg:
    for tup in split_tuples(terms_seg):
        vals=[dec(x) for x in split_fields(tup)]
        if len(vals)>=3: terms[vals[0]]=vals[1]

if tax_seg:
    for tup in split_tuples(tax_seg):
        vals=[dec(x) for x in split_fields(tup)]
        if len(vals)>=3: taxonomies[vals[0]]={"term_id":vals[1],"taxonomy":vals[2]}

if rel_seg:
    for tup in split_tuples(rel_seg):
        vals=[dec(x) for x in split_fields(tup)]
        if len(vals)>=2: relationships.setdefault(vals[0], []).append(vals[1])

if users_seg:
    for tup in split_tuples(users_seg):
        vals=[dec(x) for x in split_fields(tup)]
        if len(vals)>=8: users[vals[0]]=vals[1]

if meta_seg:
    for tup in split_tuples(meta_seg):
        vals=[dec(x) for x in split_fields(tup)]
        if len(vals)>=4:
            post_id=vals[1]; key=vals[2]; value=vals[3]
            if key=="_thumbnail_id":
                thumbnail_map[post_id]=value
            if key=="_wp_attached_file":
                attached_files[post_id]=value

def clean_html(html_text):
    html_text = re.sub(r'\[/?[^\]]+\]', '', html_text)
    html_text = html_text.replace("&nbsp;", " ")
    soup = BeautifulSoup(html_text, "html.parser")

    for tag in soup(["span","div","font","script","style"]):
        tag.unwrap()

    for img in soup.find_all("img"):
        src=img.get("src","")
        m=re.search(r'wp-content/uploads/(.+)$',src)
        if m:
            new_src="/uploads/"+m.group(1)
            alt=img.get("alt","")
            img.replace_with(f'![{alt}]({new_src})')

    for a in soup.find_all("a"):
        href=a.get("href","")
        m=re.search(r'wp-content/uploads/(.+)$',href)
        if m:
            a["href"]="/uploads/"+m.group(1)

    markdown=md(str(soup), heading_style="ATX")
    markdown=re.sub(r'\n{3,}','\n\n',markdown)
    return markdown.strip()

shutil.rmtree("content", ignore_errors=True)
shutil.rmtree("static", ignore_errors=True)
os.makedirs(CONTENT_DIR, exist_ok=True)
os.makedirs(STATIC_UPLOADS_DIR, exist_ok=True)

if os.path.exists(UPLOADS_DIR):
    shutil.copytree(UPLOADS_DIR, STATIC_UPLOADS_DIR, dirs_exist_ok=True)
    print("Uploads copiados.")

all_posts=[]

for tup in split_tuples(posts_seg):
    vals=[dec(x) for x in split_fields(tup)]
    if len(vals)>=21:
        all_posts.append(vals)
        posts_lookup[vals[0]]=vals

count=0

for vals in all_posts:
    post_id=vals[0]
    author_id=vals[1]
    post_date=vals[2]
    post_content=vals[4]
    post_title=vals[5]
    post_status=vals[7]
    post_name=vals[18]
    post_type=vals[20]

    if post_type!="post" or post_status!="publish" or not post_title.strip():
        continue

    slug=slugify(post_name if post_name else post_title)
    author=users.get(author_id,"admin")

    categories=[]
    tags=[]

    for tax_id in relationships.get(post_id,[]):
        if tax_id in taxonomies:
            term_id=taxonomies[tax_id]["term_id"]
            tax_type=taxonomies[tax_id]["taxonomy"]
            term_name=terms.get(term_id,"")
            if tax_type=="category":
                categories.append(term_name)
            elif tax_type=="post_tag":
                tags.append(term_name)

    featured=""
    if post_id in thumbnail_map:
        attach_id=thumbnail_map[post_id]
        if attach_id in attached_files:
            featured="/uploads/"+attached_files[attach_id]

    markdown_content=clean_html(post_content)
    safe_title=post_title.replace('"','')

    fm=f'---\ntitle: "{safe_title}"\ndate: {post_date}\nslug: {slug}\nauthor: "{author}"\n'
    if featured:
        fm += f'featured_image: "{featured}"\n'

    fm += "categories:\n"
    if categories:
        for c in categories: fm += f"  - {c}\n"
    else:
        fm += "  - General\n"

    fm += "tags:\n"
    if tags:
        for t in tags: fm += f"  - {t}\n"
    else:
        fm += "  - wordpress\n"

    fm += "---\n\n"

    with open(os.path.join(CONTENT_DIR, f"{slug}-{post_id}.md"), "w", encoding="utf-8") as f:
        f.write(fm + markdown_content)

    count += 1

print(f"Ultimate migration completada. {count} posts exportados.")
