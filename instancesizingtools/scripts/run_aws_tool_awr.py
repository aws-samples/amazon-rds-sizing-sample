from __future__ import print_function
import sys
import csv
import cx_Oracle
import os
import time

total = len(sys.argv)
script_name = str(sys.argv[0])
if total != 2:
   print ('Script usage: python ', script_name, ' dblist_filename > logfile/log_filename 2>&1')
   exit ()
str(sys.argv[1])
 
dblist = open(str(sys.argv[1]),"r")
#dblist = open("awrdblist.txt","r")
 
for aline in dblist.readlines():
  try:
    li=aline.strip()
    if not li.startswith("#"):
        values = li.split(',')
        user = values[0]
        passwd = values[1]
        tns = values[2]
        print (user.rstrip(),'@',tns.rstrip(),': ',time.strftime("%x %X", time.gmtime()), ' start collecting data...')
        db = cx_Oracle.connect(user, passwd, tns)
        sqllist = open("awrsqllist.txt","r")
        for sqlline in sqllist.readlines():
            values2 = sqlline.split()
            sqlfile = values2[0].rstrip()
            f = open(sqlfile,"r")
            sql = f.read()
            p = sqlfile.find('.')
            name = sqlfile[:p]
            fname = tns.rstrip() + "_" + name + ".csv"
            csv_file_dest = os.path.join('../output/', fname)
            outputFile = open(csv_file_dest,'w') # 'wb'
            output = csv.writer(outputFile, dialect='excel', lineterminator="\n", quoting=csv.QUOTE_NONNUMERIC)
            curs = db.cursor()
            curs.execute(sql)
 
            printHeader = True # include column headers in each table output
            if printHeader: # add column headers if requested
                cols = []
                for col in curs.description:
                    cols.append(col[0])
                output.writerow(cols)
 
                for row_data in curs: # add table rows
                    output.writerow(row_data)
 
            outputFile.close()
        sqllist.close()
        print (user.rstrip(),'@',tns.rstrip(),': ',time.strftime("%x %X", time.gmtime()), ' complete collecting data...')
  except Exception as e:
    print (e)
    print (user.rstrip(),'@',tns.rstrip(),': ',time.strftime("%x %X", time.gmtime()),  ' Error  collecting data...')
    pass
dblist.close()
