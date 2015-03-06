#---------------------------------------------------------------------
#
#	Created by: Johan Samuelson - Diversify - 2012
#
#	$Id:$
#
#	$URL:$
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
#
#	Convert a tab separated file to Json format
#	Optional Parameters : jsonextra,totalcount
#
#
#	{			    
#	   "rows":[		    
#	      { 		    
#		 "colname1":"colvalue",        /* Example  "userId":"c39c92878ecf7aa60df83165e2f685c5",
#		 "colname2":"colvalue"         /* Example  "loginName":"aln1209"
#	      },		    
#	      { 		    
#		 "colname1":"colvalue",
#		 "colname2":"colvalue"
#	      },		    
#	      { 		    
#		 "colname1":"colvalue",
#		 "colname2":"colvalue"
#	      } 		    
#	   ],			    
#	   jsonextra,		/* If present, jsonextra gets inserted here , else nothing */
#	   "totalcount" : 23,	/* If present, totalcount gets inserted here, else NR-1 */	    
#	   "rowcount" : 3		    
#	}			    
#
#---------------------------------------------------------------------


#
#	Variable formats: t means a string example "tllt" 1:st and 4: string should be quoted
#

#
#	Print header, Fetch all field names from first line
#

NR==1 {printf("{\n   \"success\" : true,\n   \"rows\" : ");F=NF; for(i = 1; i <= F; i++){h[i] = $i}; getline}

{


#	Open up the row, First row starts with "[" all other with ","

printf ("%s\n      {\n", NR > 2 ? "," : "[");

#	Print all columns

for(i=1; i <= F; i++) {
	
	#	Header column
	
	printf("         \"%s\":",h[i]);
	
	if ((length(formats) == 0 ) || (substr(formats,i,1) == "t") || (substr(formats,i,1) == "")) {
		
		#	Need to escape quotes for strings
		
		gsub("\"","\\\"",$i); gsub("'","\\'",$i);
		
		#	Print strings quoted
		
		printf("\"%s\"",$i);
	
	} else {
		printf("%s",$i);
	}
	
	printf("%s\n", (i < F) ? "," : "");

}

#	Close the row
printf("      }");
}

#	And finally print the summary
END {
print "\n   ],\n   "(jsonextra ? jsonextra",\n   " : "")"\"totalcount\" : "(totalCount ? totalCount : NR-1)",\n   \"rowcount\" : "NR-1"\n}"
}
