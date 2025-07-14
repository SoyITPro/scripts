docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=DontUseThisSmartPwd:)" \
-e "MSSQL_PID=Developer" -e "MSSQL_AGENT_ENABLED=true" \
-p 14333:1433 --name sqlcontainerwsl --hostname sqlcontainerwsl \
-d mcr.microsoft.com/mssql/server:2025-latest