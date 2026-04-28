import re
import os
import shutil
from markdownify import markdownify as md
from bs4 import BeautifulSoup

SQL_FILE = "jgaitpro_wpblog.sql"
OUTPUT_DIR = "hugo_markdown_posts"

# ------------------------------------------------
# LEER SQL
# ------------------------------------------------
with open(SQL_FILE, "r", encoding="utf-8", errors="ignore") as f:
    sql_data = f.read()

# ------------------------------------------------
# EXTRAER SEGMENTOS IMPORTANTES
# ------------------------------------------------
posts_match = re.search(r"INSERT INTO `wp_posts` .*? VALUES\s*(.*?);\n/\*!\d+", sql_data, re.S)
terms_match = re.search(r"INSERT INTO `wp_terms` .*? VALUES\s*(.*?);\n/\*!\d+", sql_data, re.S)
taxonomy_match = re.search(r"INSERT INTO `wp_term_taxonomy` .*? VALUES\s*(.*?);\n/\*!\d+", sql_data, re.S)
relationships_match = re.search(r"INSERT INTO `wp_term_relationships` .*? VALUES\s*(.*?);\n/\*!\d+", sql_data, re.S)
users_match = re.search(r"INSERT INTO `wp_users` .*? VALUES\s*(.*?);\n/\*!\d+", sql_data, re.S)

if not posts_match:
    print("No se encontró wp_posts")
    exit()

# ------------------------------------------------
# FUNCIONES SQL PARSER
# ------------------------------------------------
def split_tuples(s):
    tuples = []
    depth = 0
    in_string = False
    escape = False
    start = None

    for i, ch in enumerate(s):
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == "'":
                in_string = False
        else:
            if ch == "'":
                in_string = True
            elif ch == "(":
                if depth == 0:
                    start = i
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0 and start is not None:
                    tuples.append(s[start:i+1])

    return tuples


def split_fields(t):
    s = t[1:-1]
    fields = []
    current = []
    in_string = False
    escape = False

    for ch in s:
        if in_string:
            current.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == "'":
                in_string = False
        else:
            if ch == "'":
                in_string = True
                current.append(ch)
            elif ch == ",":
                fields.append("".join(current).strip())
                current = []
            else:
                current.append(ch)

    fields.append("".join(current).strip())
    return fields


def decode_field(v):
    v = v.strip()

    if v == "NULL":
        return ""

    if v.startswith("'") and v.endswith("'"):
        v = v[1:-1]
        v = v.replace("\\r\\n", "\n")
        v = v.replace("\\n", "\n")
        v = v.replace("\\'", "'")
        v = v.replace('\\"', '"')

    return v


def slugify(s):
    s = re.sub(r'https?://\S+', '', s)
    s = re.sub(r'[^a-zA-Z0-9]+', '-', s)
    s = s.strip("-").lower()
    return s[:90] if s else "post"

# ------------------------------------------------
# PARSEAR TABLAS AUXILIARES
# ------------------------------------------------
terms = {}
taxonomies = {}
relationships = {}
users = {}

if terms_match:
    for tup in split_tuples(terms_match.group(1)):
        vals = [decode_field(x) for x in split_fields(tup)]
        if len(vals) >= 3:
            terms[vals[0]] = vals[1]

if taxonomy_match:
    for tup in split_tuples(taxonomy_match.group(1)):
        vals = [decode_field(x) for x in split_fields(tup)]
        if len(vals) >= 3:
            taxonomies[vals[0]] = {
                "term_id": vals[1],
                "taxonomy": vals[2]
            }

if relationships_match:
    for tup in split_tuples(relationships_match.group(1)):
        vals = [decode_field(x) for x in split_fields(tup)]
        if len(vals) >= 2:
            post_id = vals[0]
            tax_id = vals[1]
            relationships.setdefault(post_id, []).append(tax_id)

if users_match:
    for tup in split_tuples(users_match.group(1)):
        vals = [decode_field(x) for x in split_fields(tup)]
        if len(vals) >= 8:
            users[vals[0]] = vals[1]

# ------------------------------------------------
# LIMPIEZA HTML PROFESIONAL
# ------------------------------------------------
def clean_html(html_text):

    html_text = re.sub(r'\[/?[^\]]+\]', '', html_text)
    html_text = re.sub(r'&nbsp;', ' ', html_text)

    soup = BeautifulSoup(html_text, "html.parser")

    for tag in soup(["span", "div", "font", "script", "style"]):
        tag.unwrap()

    for img in soup.find_all("img"):
        src = img.get("src", "")
        alt = img.get("alt", "")
        img.replace_with(f'![{alt}]({src})')

    cleaned = str(soup)

    markdown = md(cleaned, heading_style="ATX")

    markdown = re.sub(r'\n{3,}', '\n\n', markdown)

    return markdown.strip()

# ------------------------------------------------
# PREPARAR SALIDA
# ------------------------------------------------
shutil.rmtree(OUTPUT_DIR, ignore_errors=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ------------------------------------------------
# PROCESAR POSTS
# ------------------------------------------------
count = 0

for tup in split_tuples(posts_match.group(1)):
    vals = [decode_field(x) for x in split_fields(tup)]

    if len(vals) < 21:
        continue

    post_id = vals[0]
    author_id = vals[1]
    post_date = vals[2]
    post_content = vals[4]
    post_title = vals[5]
    post_status = vals[7]
    post_name = vals[18]
    post_type = vals[20]

    if post_type != "post" or post_status != "publish" or not post_title.strip():
        continue

    slug = slugify(post_name if post_name else post_title)
    author = users.get(author_id, "admin")

    categories = []
    tags = []

    for tax_id in relationships.get(post_id, []):
        if tax_id in taxonomies:
            term_id = taxonomies[tax_id]["term_id"]
            taxonomy_type = taxonomies[tax_id]["taxonomy"]
            term_name = terms.get(term_id, "")

            if taxonomy_type == "category":
                categories.append(term_name)

            if taxonomy_type == "post_tag":
                tags.append(term_name)

    markdown_content = clean_html(post_content)

    safe_title = post_title.replace('"', '')

    frontmatter = f"""---
title: "{safe_title}"
date: {post_date}
slug: {slug}
author: "{author}"
categories:
"""

    if categories:
        for c in categories:
            frontmatter += f"  - {c}\n"
    else:
        frontmatter += "  - General\n"

    frontmatter += "tags:\n"

    if tags:
        for t in tags:
            frontmatter += f"  - {t}\n"
    else:
        frontmatter += "  - wordpress\n"

    frontmatter += "---\n\n"

    final_text = frontmatter + markdown_content

    filename = f"{slug}-{post_id}.md"

    with open(os.path.join(OUTPUT_DIR, filename), "w", encoding="utf-8") as f:
        f.write(final_text)

    count += 1

print(f"Se exportaron {count} posts profesionales en '{OUTPUT_DIR}'")