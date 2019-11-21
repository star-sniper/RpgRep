000100191120     F*****************************************************************************************
000101191120     F* THIS PROGRAM USES A CURSOR TO LOAD A TEMPORARY RESULT TABLE THAT JOINS THE ORDERS,        *
000102191120     F* ORDERLINE, CUSTOMER, PART AND SALESREP TABLES.  ORDER NUMBER IS USED AS A CONTROL BREAK   *
000103191120     F* FIELD WHERE CUSTOMER TOTALS ARE PRINTED ON NEW ORDER NUMBERS                              *
000104191120     F*                                                                                           *
000105191120     F*********************************************************************************************
000106191120
000107191120     FQPRINT    O    F  132        PRINTER OFLIND(*INOF) FORMOFL(60) FORMLEN(66)
000108191120     D CustomerRecord  DS
000109191120     D CustId                         6
000110191120     D FullName                      31
000111191120     D City                          20
000112191120     D Purchase                       7  2
000113191120     D PDate                           D
000114191120     D Province                      10
000115191120     D ProvinceH       S             10
000116191120     D TotalCost       S              8  2
000117191120     D TotalRecords    S              5  0
000118191120     D TotalExtended   S              9  2
000119191120     D OntarioTot      S              3  0
000120191120     D QuebecTot       S              3  0
000121191120     D ManitobaTot     S              3  0
000122191120     D EndOfFile       S               N
000123191120     C/EJECT
000124191120     C********************************************************************************************
000125191120     C*                        ***   M A I N   R O U T I N E   ***                               *
000126191120     C********************************************************************************************
000127191120      /FREE
000128191120               EXSR PrepareFiles;
000129191120               EXCEPT HEADINGS;
000130191120               EXSR GetRow;
000131191120               Except NewProv;
000132191120               ProvinceH = Province;
000133191120               DOW NOT EndOfFile;
000134191120                   IF *INOF = *ON;
000135191120                       EXCEPT HEADINGS;
000136191120                      *INOF = *OFF;
000137191120                   ENDIF;
000138191120                   If ProvinceH = Province;
000139191120                      Except Detail;
000140191120                   Else;
000141191120                      ProvinceH = Province;
000142191120                      Except NewProv;
000143191120                      Except Detail;
000144191120                   EndIf;
000145191120                   TotalCost     = TotalCost     + Purchase;
000146191120                   TotalRecords= TotalRecords + 1;
000147191120                   EXSR GetRow;
000148191120               ENDDO;
000149191120               EXSR   WRAPUP;
000150191120               EXCEPT Totals;
000151191120               *INLR = *ON;
000152191120               RETURN;
000153191120       //************************************************************************************
000154191120       // O P E N F I L E S   S U B R O U T I N E
000155191120       //*****************************************************************************************
000156191120        BEGSR  PrepareFiles;
000157191120       // S E T   U P   T H E   T E M P O R A R Y   R E S U L T  S T R U C T U R E
000158191120             EXEC SQL
000159191120                DECLARE ALLPROVCURSOR CURSOR
000160191120                  FOR
000161191120                  SELECT CUSTID, TRIM(FNAME) || ' ' || TRIM(LNAME), CITY,
000162191120                         PURCHASE,
000163191120                         PDATE, 'Ontario' AS PROVINCE
000164191120                  FROM BCI433LIB/ONTARIO
000165191120                  WHERE PURCHASE > 150
000166191120                  UNION ALL
000167191120                  SELECT CUSTID, TRIM(FNAME) || ' ' || TRIM(LNAME), CITY,
000168191120                          PURCHASE,
000169191120                         PDATE, 'Quebec' AS PROVINCE
000170191120                  FROM BCI433LIB/QUEBEC
000171191120                  WHERE PURCHASE > 150
000172191120                  UNION ALL
000173191120                  SELECT CUSTID, TRIM(FNAME) || ' ' || TRIM(LNAME), CITY,
000174191120                          PURCHASE,
000175191120                         PDATE, 'Manitoba' AS PROVINCE
000176191120                  FROM BCI433LIB/MANITOBA
000177191120                  WHERE PURCHASE > 150
000178191120                    FOR READ ONLY;
000179191120
000180191120             EXEC SQL
000181191120               OPEN ALLPROVCURSOR;
000182191120             IF SQLCODE <> 0 OR SQLWN0 = 'W';
000183191120               EndOfFile = *ON;
000184191120             ENDIF;
000185191120       // A   T E M P O R A R Y   R E S U L T   T A B L E   I S   C R E A T E D
000186191120           ENDSR;
000187191120       //****************************************************************************************
000188191120       //   G E T     R O W    S U B R O U T I N E
000189191120       //*****************************************************************************************
000190191120           BEGSR     GETROW;
000191191120                  EXEC SQL
000192191120                    FETCH NEXT
000193191120                      FROM ALLPROVCURSOR
000194191120                      INTO :CustomerRecord;
000195191120                  IF SQLCODE <> 0 OR SQLWN0 = 'W';
000196191120                    EndOfFile = *ON;
000197191120                  ENDIF;
000198191120            ENDSR;
000199191120       //****************************************************************************************
000200191120       // W R A P U P     S U B R O U T I N E
000201191120       //*****************************************************************************************
000202191120          BEGSR WRAPUP;
000203191120                EXEC SQL
000204191120                  CLOSE ALLPROVCURSOR;
000205191120
000206191120                IF SQLCODE <> 0 OR SQLWN0 = 'W';
000207191120                  EndOfFile = *ON;
000208191120                ENDIF;
000209191120
000210191120             EXEC SQL
000211191120               SELECT COUNT(*) INTO :OntarioTot
000212191120                 FROM BCI433LIB/ONTARIO
000213191120                 WHERE PURCHASE <= 150;
000214191120
000215191120             IF SQLCODE <> 0 OR SQLWN0 = 'W';
000216191120               OntarioTot = -999;
000217191120             ENDIF;
000218191120
000219191120             EXEC SQL
000220191120               SELECT COUNT(*) INTO :QuebecTot
000221191120                 FROM BCI433LIB/QUEBEC
000222191120                 WHERE PURCHASE <= 150;
000223191120
000224191120             IF SQLCODE <> 0 OR SQLWN0 = 'W';
000225191120               QuebecTot = -999;
000226191120             ENDIF;
000227191120
000228191120
000229191120             EXEC SQL
000230191120                SELECT COUNT(*) INTO :ManitobaTot
000231191120                 FROM BCI433LIB/MANITOBA
000232191120                 WHERE PURCHASE <= 150;
000233191120
000234191120             IF SQLCODE <> 0 OR SQLWN0 = 'W';
000235191120               ManitobaTot = -999;
000236191120             ENDIF;
000237191120         ENDSR;
000238191120      /END-FREE
000239191120     OQPRINT    E            HEADINGS       2 02
000240191120     O                                           67 'Customers > $150.00'
000241191120     O                                          110 'Page:'
000242191120     O                       PAGE               115
000243191120     O          E            HEADINGS       1
000244191120     O                                            8 'Province'
000245191120     O                                           23 'Customer ID'
000246191120     O                                           42 'Full Name'
000247191120     O                                           64 'City'
000248191120     O                                           90 'Purchase'
000249191120     O                                          101 'Purchase'
000250191120     O          E            HEADINGS       2
000251191120     O                                           89 'Amount'
000252191120     O                                           99 'Date'
000253191120     O          E            NewProv        1
000254191120     O                       Province            10
000255191120     O          E            DETAIL         1
000256191120     O                       CustID              20
000257191120     O                       FullName            61
000258191120     O                       City                74
000259191120     O                       Purchase      1     90
000260191120     O                       PDate              103
000261191120     O          E            Totals      2  1
000262191120     O                                           79 'Total Amount:'
000263191120     O                       TotalCost     1     90
000264191120     O          E            Totals      1  1
000265191120     O                                           17 'Total Customers:'
000266191120     O                       TotalRecords  1     24
000267191120     O          E            TOTALS         2 02
000268191120     O                                           67 'Customers <= $150.00'
000269191120     O                                          110 'Page:'
000270191120     O                       PAGE               115
000271191120     O          E            Totals         2
000272191120     O                                           18 'Ontario'
000273191120     O                                           41 'Quebec'
000274191120     O                                           69 'Manitoba'
000275191120     O          E            Totals         1
000276191120     O                       OntarioTot    1     15
000277191120     O                       QuebecTot     1     38
000278191120     O                       ManitobaTot   1     66
