import json
import os
import argparse
import sys


def write_conf(data, filename="/opt/trifacta/conf/trifacta-conf.json"):
    with open (filename, "w") as f:
        json.dump(data, f, indent=1)

def edit_conf(keyVaultUrl, applicationid, directoryid, secret, dbserviceUrl, storageaccount, storagecontainer):
    with open("/opt/trifacta/conf/trifacta-conf.json", encoding='utf-8') as triconf_file:
        storageUri = "abfss://"+ storagecontainer + "@" + storageaccount + ".dfs.core.windows.net/"
        data = json.load(triconf_file)
        data["azure"]["keyVaultUrl"] = keyVaultUrl
        data["azure"]["applicationid"] = applicationid
        data["azure"]["directoryid"] = directoryid
        data["azure"]["secret"] = secret
        data["databricks"]["serviceUrl"] = dbserviceUrl
        data["webapp"]["runInDatabricks"] = True
        data["webapp"]["storageProtocal"] = "abfss"
        data["spark-job-service"]["hiveDependenciesLocation"] = "%(topOfTree)s/hadoop-deps/cdh-6.2/build/libs"
        data["fileStorage"]["whitelist"] = ["sftp","abfss"]
        data["fileStorage"]["defaultBaseUris"] = [storageUri]
        data["aws"]["s3"]["enabled"] = False

    write_conf(data)
    print("Wrote new settings to triconf", file = sys.stdout)
    restart_trifacta()

def restart_trifacta():
    os.system('service trifacta restart')

def main():
    parser = argparse.ArgumentParser(description="Configure Trifacta after deployment on Azure using ARM template")
    parser.add_argument('-k', '--keyVaultUrl', help='Key Vault URL', required=True, type=str)
    parser.add_argument('-a', '--applicationid', help='Application ID', required=True, type=str)
    parser.add_argument('-d', '--directoryid', help='Directory ID', required=True, type=str)
    parser.add_argument('-s', '--secret', help='Application Secret', required=True, type=str)
    parser.add_argument('-D', '--dbserviceUrl', help='Databricks Service URL', required=True, type=str)
    parser.add_argument('-S', '--storageaccount', help='Storage Account name', required=True, type=str)
    parser.add_argument('-c', '--storagecontainer', help='Storage Account container name', required=True, type=str)

    args = parser.parse_args()
    

    edit_conf(**vars(args))

if __name__ == "__main__":
    main()