WITH normalized_suppliers AS (
    SELECT 
        *,
        CASE 
            -- CHINA CONSTRUCTION EIGHTH DIVISION variations
            WHEN UPPER(supplier) ~ '\yCHINA\s+CONSTRUCT(ION)?\s+(EIGHT(H)?|8(TH)?)\s+(ENGINEERING\s+)?DIVISION\y'
                THEN 'CHINA CONSTRUCTION EIGHTH ENGINEERING DIVISION (CCEED)'
				
            -- UNOPS variations
            WHEN UPPER(supplier) ~ '.*\y(UNOPS|UNITED NATIONS OFFICE.*PROJECT SERVICE)\y.*'
                THEN 'UNITED NATIONS OFFICE FOR PROJECT SERVICES (UNOPS)'
            
            -- CHINA RAILWAY variations
			WHEN UPPER(supplier) ~ '\y(CHINA\s+RAILWAY?S?\s+18TH\s+BUREAU\s+GROUP|CHINA\s+RAILWAY?S?\s*\(CRCC)\y'
                THEN 'CHINA RAILWAYS CORPORATION LIMITED (CRCC)'
				
            -- WIETC variations
            WHEN UPPER(supplier) ~ '\y(WIETC|WEIHAI INTERNATIONAL)\y'
                THEN 'WEIHAI INTERNATIONAL ECONOMIC & TECHNICAL COOPERATIVE (WIETC)'
				
            -- UNICEF variations
            WHEN REGEXP_REPLACE(UPPER(supplier), '[.,\-\s()]', '') ~ '(UNICEF|UNITEDNATIONSCHILDRENSFUND)'
                THEN 'UNITED NATIONS CHILDREN''S FUND (UNICEF)'

            -- CGC variations
            WHEN UPPER(supplier) ~ '\yCHINA\s+GEO[\s\-]+ENGINEERING\s+CORPORATION\y'
                OR REGEXP_REPLACE(UPPER(supplier), '[.,\-\s()]', '') ~ '(CGC|CHINAGEOENGINEERING)'
                THEN 'CHINA GEO-ENGINEERING CORPORATION (CGC)'

			-- CRBC/China Road and Bridge variations
            WHEN UPPER(supplier) ~ '\y(CRBC|CHINA\s+ROAD\s+AND\s+BRIDGE)\s*(CORPORATION)?\y'
				OR UPPER(supplier) ~ '\yCHINA\s+ROADS?\s*&?\s+BRIDGE\s+CORPORATION\y'
                THEN 'CHINA ROAD AND BRIDGE CORPORATION (CRCC)'
                
            -- SINOHYDRO variations
            WHEN UPPER(supplier) ~ '\ySINOHYDRO\y'
                THEN 'SINOHYDRO CORPORATION LIMITED'

			-- VIMA variations
            WHEN UPPER(supplier) ~ '\yVIMA\y'
                THEN 'VIMA (VISION MADA)'

			-- ZHONGMEI variations
            WHEN UPPER(supplier) ~ '\yZHONGMEI\s+ENGINEERING\s+GROUP[E]?\s*(LTD|LIMITED)?\y'
                THEN 'ZHONGMEI ENGINEERING GROUP LIMITED'

            -- SALAMA conditions and variation
            WHEN UPPER(supplier) ~ '\y(SALAMA|CENTRALE? D''ACHAT.?SALAMA)\y' 
                AND NOT UPPER(supplier) ~ '.*(TSALAMA|ANDRIAT?SALAMA|RAZAFIN?TSALAMA|RASOARIN?TSALAMA|VOAHARY|AGEX MMST).*'
                THEN 'SALAMA'

			-- SOGEA SATOM variations
            WHEN UPPER(supplier) ~ '\ySOGEA[\s\-]SATOM(\s+FRANCE)?\y'
                THEN 'SOGEA SATOM'
			   
            -- GEOFIT variations
            WHEN UPPER(supplier) ~ '\y(GROUPEMENT\s+)?GEOFIT\s+EXPERT(,\s+GEOSYSTEM\s+&\s+DEVELOPPEMENT)?\y'
                THEN 'GEOFIT EXPERT'
    
            -- FANOMEZANA variations
            WHEN UPPER(supplier) ~ '\yENTREPRISE\s+FANOMEZANA(\s+KDO\s+SARLU)?(\s*[\-]\s*STAT\s+\d+.*)?'
                THEN 'ENTREPRISE FANOMEZANA'
                
            -- EGECOM variations    
            WHEN UPPER(supplier) ~ '\y(ENTREPRISE\s+)?EGECOM\y'
                THEN 'EGECOM'
    
            -- JB variations
            WHEN UPPER(supplier) ~ '\y(SOCIET[EÉ]\s+)?JB(\s+MADAGASCAR)?\y'
                THEN 'SOCIETE JB'

			-- COGELEC variations
			WHEN UPPER(supplier) ~ '\yCOGELEC(\s+MADAGASCAR)?\y'
                THEN 'COGELEC'
			        
            -- LA PRECISION variations
            WHEN UPPER(supplier) ~ '\y(ENTREPRISE\s+)?LA\s+PRECISION(\s+SARL)?\y'
                THEN 'LA PRECISION'
			    
            -- BRL variations
            WHEN UPPER(supplier) ~ '\y(GROUPEMENT\s+)?BRL(\s+ING[EÉ]NIERIE|\s+MADAGASCAR)?'
                OR UPPER(supplier) ~ '\yBRLI\y'
                OR UPPER(supplier) ~ '\yBRL\/BEST\y'
                OR UPPER(supplier) ~ '\yGROUPEMENT\s+SCET\s+TUNISIE\s*\/\s*BRL\s+MADAGASCAR\y'
                OR UPPER(supplier) ~ '\yGROUPEMENT\s+BRL\s+ING[EÉ]NIERIE[\s\-]+BRL\s+MADAGASCAR[\s\-]+BEST\y'
                OR UPPER(supplier) ~ '\yGROUPEMENT\s+BRL\s+INGENIERIE,\s+SEURECA,\s+HYDROCONSEIL\s+ET\s+BRL\s+MADAGASCAR\y'
                THEN 'BRL INGENIERIE'
				
            -- INSTAT variations
            WHEN UPPER(supplier) ~ '\y(INSTAT|INSTITUT\s+NATIONAL\s+DE\s+LA\s+STATISTIQUE)\y'
                THEN 'INSTITUT NATIONAL DE LA STATISTIQUE (INSTAT)'

			-- HAROLD variations
            WHEN UPPER(supplier) ~ '\yHAROLD\y'
                OR UPPER(supplier) ~ '\yGROUPEMENT\s+FITALIA\-HAROLD\-TSILANIZARA\y'
                THEN 'HAROLD'

			-- SOMEEIM variations
            WHEN UPPER(supplier) ~ '\y(ENTREPRISE\s+)?SOMEEIM(\s+SARL)?\y'
                OR UPPER(supplier) ~ '\ySOCI[EÉ]T[EÉ]\s+MALGACHE\s+D[''´`'']ENTRETIEN\s+ET\s+D[''´`'']EQUIPEMENT\s+IMMOBILIER(\s*\(SOMEEIM\))?\y'
                THEN 'SOCIETE MALGACHE D''ENTRETIEN ET D''EQUIPEMENT IMMOBILIER (SOMEEIM)'
				
			-- ONG/NGO variations
            WHEN UPPER(supplier) ~ '\yA2DM\y'
                OR UPPER(supplier) ~ '\yASSOCIATION\s+DAPPUI\s+AU\s+D[EÉ]VELOPEMENT\s+DE\s+MADAGASCAR\y'
                OR UPPER(supplier) ~ '\yGROUPEMENT\s+A2DM\y'
                OR UPPER(supplier) ~ '\yADIE\y'
                OR UPPER(supplier) ~ '\yASSOCIATION\s+(POUR\s+LE\s+)?D[EÉ]VELOPPEMENT\s+INT[EÉ]GR[EÉ]\y'
                OR UPPER(supplier) ~ '\yACTION\s+SOCIO\s+SANITAIRE\s+ORGANISATION\s+SECOURS\y'
                OR UPPER(supplier) ~ '\y(ONG|O\.N\.G)(\s+|\/)\y'
                OR UPPER(supplier) ~ '\yASSOCIATION\s+(ENDRIKO|TANTELI|FIKAMBANAN)\y'
                THEN 'ONG'

			-- ISO CONSTRUCTION variations
            WHEN UPPER(supplier) ~ '\y(ENTREPRISE\s+)?ISO\s+CONSTRUCTION\y'
                THEN 'ISO CONSTRUCTION'
                
			-- WFP variations
            WHEN UPPER(supplier) ~ '\y(WFP|PAM|WORLD\s+FOOD\s+PROGRAMME|PROGRAMME\s+ALIMENTAIRE\s+MONDIAL)\y'
                THEN 'WORLD FOOD PROGRAMME (WFP)'

			-- ARTELIA variations
            WHEN UPPER(supplier) ~ '\yARTELIA\y'
                THEN 'ARTELIA MADAGASCAR'
			    
            -- EGIS INFRAMAD variations
            WHEN UPPER(supplier) ~ '\yEGIS\s+INFRAMAD(\s*\-\s*MADAGASCAR)?\y'
                OR UPPER(supplier) ~ '\yGROUPEMENT\s+EGIS\s+INFRAMAD(\s*\/\s*[^\/]+)*\y'
                THEN 'EGIS'
     
            -- HENRI FRAISE variations
            WHEN UPPER(supplier) ~ '\yHENRI\s+FRAISE\s+FILS\s+&\s+CIE(\s+SA)?\y'
                THEN 'HENRI FRAISE FILS & CIE'
				
			-- AGEX variations (all should normalize to one entity except VOAHARY SALAMA)              
            WHEN UPPER(supplier) ~ '\y(AGEX|.*_AGEX_FID)\y'
				OR UPPER(supplier) ~ '\yAGEX MMST\y'
				OR UPPER(supplier) ~ '\yVOAHARY SALAMA\y'
				OR UPPER(supplier) ~ '\y(ACDM|AJAH|AJDS|AJDHN)\y'
				OR UPPER(supplier) ~ '\yASSOCIATION AJDS\y'
				OR UPPER(supplier) ~ '\yACTION DES JEUNES POUR LE D[EÉ]VELOPPEMENT DE L''HUMANIT[EÉ] ET DE LA NATURE\y'
				OR UPPER(supplier) ~ '\yONG ACTION DES JEUNES POUR LE DEVELOPPEMENT DE L''HUMANITE ET DE LA NATURE\y'
				OR UPPER(supplier) ~ '\y(ONG\s+)?ACTION\s+DES\s+JEUNES\s+POUR\s+LE\s+D[EÉ]VELOPPEMENT\s+DE\s+L[''´]\s*HUMANIT[EÉ]\s+ET\s+DE\s+LA\s+NATURE(\s*\(AJDHN\))?\y'
				THEN 'AGEX FID'

			-- SERT variations
            WHEN UPPER(supplier) ~ '\ySERT\y' AND NOT UPPER(supplier) ~ '\yDESERT\y'
                THEN 'SERT'
			    
            -- NEXT HOPE variations
            WHEN UPPER(supplier) ~ '\yNEXT\s*HOP[ER]\y'
                THEN 'NEXT HOPE'
				
            -- FID variations (expanded)
            WHEN UPPER(supplier) ~ '\yFONDS\s+D[''´`'']INTERVENTION\s+POUR\s+LE\s+D[EÉ]VELOPPEMENT(\s*\(FID\))?\y'
                OR UPPER(supplier) ~ '\yFID\y'
                OR UPPER(supplier) ~ '\yFONDS?\s+INTERVENTION\s+DEVELOPPEMENT\y'
                THEN 'FONDS D''INTERVENTION POUR LE DEVELOPPEMENT (FID)'
				
			-- WHO/OMS variations
            WHEN UPPER(supplier) ~ '\y(OMS[\s\-]GENEVE|ORGANISATION\s+MONDIALE\s+DE\s+LA\s+SANTE)\y'
                THEN 'ORGANISATION MONDIALE DE LA SANTE (OMS)'

			-- THE BEST variation
            WHEN UPPER(supplier) ~ '\y(THE BEST)\y'
                THEN 'THE BEST'
    
            -- FIADANANTSOA variations
            WHEN UPPER(supplier) ~ '\y(ETS\s+)?FIADANANTSOA\y'
                THEN 'ETS FIADANANTSOA'
				     
            -- SETEC variations
            WHEN UPPER(supplier) ~ '\ySETEC(\s+(AFRIQUE|INTERNATIONAL|SUCCURSALE\s+DE\s+MADAGASCAR))\y'
                OR UPPER(supplier) ~ '\yGROUPEMENT\s+SETEC\s+MADAGASCAR\s*\/\s*SETEC\s+INTERNATIONAL\s*\/\s*ASA\s+TARATRA\y'
                THEN 'SETEC'
				
			-- ZTE variations
            WHEN UPPER(supplier) ~ '\y(SOCIÉTÉ\s+)?ZTE(\s+CORPORATION)?\y'
                THEN 'ZTE CORPORATION'
    
            -- MEGAPRINT variations
            WHEN UPPER(supplier) ~ 'MEGA[[:space:]]*PRINT'
                THEN 'MEGAPRINT'
				
            -- MT LAB variations
            WHEN UPPER(supplier) ~ '\y(MIARY\s*\-\s*TECH\s*\-\s*LAB\s+)?(MT\s*LAB|MTLAB)\y'
                THEN 'MIARY TECH LAB (MTLAB)'
				
            -- GROUPE TAHINA variations
            WHEN UPPER(supplier) ~ '\yGROUPE\s+TAHINA(\s+SARL)?\y'
                THEN 'GROUPE TAHINA'
				
			-- PITAMBRA variations    
            WHEN UPPER(supplier) ~ '\yPITAMBRA\s+BOOKS\s+PVT(\s+LTD)?\y'
                THEN 'PITAMBRA BOOKS PVT LTD'
				
            -- BPC variations
            WHEN UPPER(supplier) ~ '\yBPC(\s+AG)?\y'
                THEN 'BPC'

			-- All Tourism Offices grouped together
            WHEN UPPER(supplier) ~ '\yOFFICE\s+(R[EÉ]GIONAL\s+)?DU\s+TOURISME\y'
				OR UPPER(supplier) ~ '\yOFFICE\s+(NATIONAL\s+)?DU\s+TOURISME\y'
				OR UPPER(supplier) ~ '\y(CTM|CONFEDERATION\s+DU\s+TOURISME\s+DE\s+MADAGASCAR)\y'
                THEN 'OFFICE DU TOURISME'

            -- WWF variations
            WHEN UPPER(supplier) ~ '\yWWF\y'
                OR UPPER(supplier) ~ '\yWORLD\s+WIDE\s+FUND\s+FOR\s+NATURE(\s*\(MADAGASCAR(\s+COUNTRY)?\s+OFFICE\))?\y'
                THEN 'WORLD WIDE FUND FOR NATURE (WWF)'
				    
            -- GERCO variations
            WHEN UPPER(supplier) ~ 'GERCO([[:space:]]+(MADAGASCAR|SARLU))?'
                THEN 'GERCO'
				
			-- GLOBAL TECHNOLOGIES
            WHEN UPPER(supplier) ~ '\yGLOBAL TECHNOLOG(Y|IES)\y'
                THEN 'GLOBAL TECHNOLOGIES ET ENERGIES (GTE)'
			    
            -- ERRA variations
            WHEN UPPER(supplier) ~ '\yERRA\y'
                OR UPPER(supplier) ~ '\yENTREPRISE\s+(DE\s+)?R[EÉ]ALISATION\s+ET\s+DE\s+REVALORISATION\s+DES\s+AM[EÉ]NAGEMENTS(\s*\(ERRA\))?\y'
                OR UPPER(supplier) ~ '\yENTREPRISE\s+ERRA\y'
                THEN 'ENTREPRISE DE REALISATION ET DE REVALORISATION DES AMENAGEMENTS (ERRA)'
			        
            -- FHI variations
            WHEN UPPER(supplier) ~ 'FAMILY[[:space:]]+HEALTH[[:space:]]+INTERNATIONAL[[:space:]]*\(FHI\)'
                OR UPPER(supplier) ~ 'FHI[[:space:]]+SOLUTIONS[[:space:]]+LLC'
                THEN 'FAMILY HEALTH INTERNATIONAL (FHI)'
				
			-- AER variations
            WHEN UPPER(supplier) ~ 'ENTREPRISE[[:space:]]+A\.?E\.?R\.?'
                OR UPPER(supplier) ~ 'ANA[EËÊ]L[[:space:]]+ETUDES[[:space:]]+ET[[:space:]]+R[EÉ]ALISATIONS[[:space:]]*\(A\.?E\.?R\.?\)'
                THEN 'ANAEL ETUDES ET REALISATIONS (AER)'
				    
            -- FLY TECHNOLOGIE variations
            WHEN UPPER(supplier) ~ '\yFLY\s+TECHNOLOGI[ES]+\y'
                THEN 'FLY TECHNOLOGIES'
				    
            -- SICAM variations
            WHEN UPPER(supplier) ~ '\ySICAM(\s+(CFAO|MADAGASCAR))?\y'
                THEN 'SICAM'
				
			-- INSTITUT PASTEUR variations
            WHEN UPPER(supplier) ~ '\yINSTITUT\s+PASTEUR\s+DE\s+MADAGASCAR(\s*\(IPM\))?\y'
                THEN 'INSTITUT PASTEUR DE MADAGASCAR'

			-- SANDRATRA variations
            WHEN UPPER(supplier) ~ '\ySANDRATRA\y'
                AND NOT UPPER(supplier) ~ '.*(NASANDRATRA|ZONASANDRATRA).*'
                THEN 'SANDRATRA'

            -- BRICOBAT variations
            WHEN UPPER(supplier) ~ '\yBRICO[T]?BAT(\s+S\.?A\.?)?\y'
                THEN 'BRICOBAT'

			-- ACS variations
			WHEN UPPER(supplier) ~ 'ACS([[:space:]]+MADAGASCAR)?'
			    OR UPPER(supplier) ~ 'ACS[[:space:]]*\([[:space:]]*AUDIT[[:space:]]+CONSEIL[[:space:]]+SERVICE[[:space:]]*\)'
			    OR UPPER(supplier) ~ 'AUDIT[[:space:]]+CONSEIL[[:space:]]+ET[[:space:]]+SERVICE'
			    THEN 'AUDIT CONSEIL SERVICE (ACS)'

			-- AC DELCO variations
			WHEN UPPER(supplier) ~ '(ASSOCIATION[[:space:]]+)?AC[[:space:]]+DELCO'
			    THEN 'AC DELCO'
				
            WHEN UPPER(supplier) ~ '\yHYDROTECMAD\y'
                THEN 'HYDROTECMAD'
                
            WHEN UPPER(supplier) ~ '\yDELTA AUDIT\y'
                THEN 'DELTA AUDIT'
                
            WHEN UPPER(supplier) ~ '\ySOFTWELL\y'
                THEN 'SOFTWELL'
                
            WHEN UPPER(supplier) ~ '\yITET\y'
                THEN 'INFORMATION TECHNOLOGY ENGINEERING & TRADE (ITET)'
            
			-- TELMA variations
            WHEN UPPER(supplier) ~ '\yTELMA\y'
                THEN 'TELMA'
				
			-- ORANGE variations
            WHEN UPPER(supplier) ~ '\yORANGE\y'
                THEN 'ORANGE'
				
			-- AIRTEL variations
            WHEN UPPER(supplier) ~ '\yAIRTEL\y'
                THEN 'AIRTEL'
			
			-- ORINTSOA variations
			WHEN UPPER(supplier) ~ 'ORINTSOA[[:space:]]+BUILDING([[:space:]]+ENTREPRISE)?'
			    THEN 'ORINTSOA BUILDING'

			-- AGRIPRO variations
			WHEN UPPER(supplier) ~ 'AGRIPRO([[:space:]]+AGRICULTURE[[:space:]]*&[[:space:]]*PROFESSIONNAL)?'
			    OR UPPER(supplier) ~ 'AGRIPRO[[:space:]]+SARL'
			    THEN 'AGRIPRO'

			-- ASA variations
			WHEN UPPER(supplier) ~ 'ASSOCIATION[[:space:]]+ASA'
			    OR UPPER(supplier) ~ 'AINA[[:space:]]+SOA[[:space:]]+NY[[:space:]]+AVO([[:space:]]*\(ASA\))?'
			    THEN 'AINA SOA NY AVO (ASA)'

			-- ALPHA SERVICE variations
			WHEN UPPER(supplier) ~ 'ALPHA[[:space:]]+SERVICE[S]?([[:space:]]+MAHAJANGA)?'
			    THEN 'ALPHA SERVICES'

			-- ALTEC variations
			WHEN UPPER(supplier) ~ 'ALTEC([[:space:]]+MADAGASCAR)?'
				THEN 'ALTEC'

			-- AMBININTSOA variations
			WHEN UPPER(supplier) ~ 'AMBININTSOA([[:space:]]+ENTREPRISE)?'
			    THEN 'AMBININTSOA'

			-- ANDRIAMAMONJY variations
			WHEN UPPER(supplier) ~ 'ANDRIAMAMONJY[[:space:]]+MAHANDRIVOLOLONA[[:space:]]+RIJARIV(ELO)?'
			    THEN 'ANDRIAMAMONJY MAHANDRIVOLOLONA RIJARIVELO'

			-- ANDRIAMBELO variations
			WHEN UPPER(supplier) ~ 'ANDRIAMBELO[[:space:]]+JOCELYN([[:space:]]+NIRINIAINA)?'
			    THEN 'ANDRIAMBELO JOCELYN NIRINIAINA'

			-- ANDRIAMIHAJA variations
			WHEN UPPER(supplier) ~ 'ANDRIAMIHAJA[[:space:]]+RIVONTSOA([[:space:]]+SOLOHERILOVA)?'
			    THEN 'ANDRIAMIHAJA RIVONTSOA SOLOHERILOVA'

			-- ANDRIANAIVO variations
			WHEN UPPER(supplier) ~ 'ANDRIANAIVO[[:space:]]+FIDISOA[[:space:]]*TSIFERANA[[:space:]]+BENJAMIN'
			    OR UPPER(supplier) ~ 'ANDRIANAIVO[[:space:]]+FIDISOATSIFERANA[[:space:]]+BENJAMIN'
			    THEN 'ANDRIANAIVO FIDISOA TSIFERANA BENJAMIN'

			-- ANDRIANAIVOMANANA variations
			WHEN UPPER(supplier) ~ 'ANDRIANAIVOMANANA[[:space:]]+(NIRINA[[:space:]]+TOJOSOA|TOJOSOA[[:space:]]+NIRINA)[[:space:]]+MICHA[EËÉ]L'
			    THEN 'ANDRIANAIVOMANANA TOJOSOA NIRINA MICHAEL'

			-- ANDRIANARIVELO variations
			WHEN UPPER(supplier) ~ 'ANDRIANARIVELO[[:space:]]+SEDERA([[:space:]]+VALOHERY)?'
			    THEN 'ANDRIANARIVELO SEDERA VALOHERY'

			-- ANDRIANJAKANA variations
			WHEN UPPER(supplier) ~ 'ANDRIANJAKANA[[:space:]]+MBINOARINTSOA([[:space:]]+JULLIASSE)?'
			    THEN 'ANDRIANJAKANA MBINOARINTSOA JULLIASSE'

			-- ANJARA variations
			-- WHEN UPPER(supplier) ~ 'ANJARA[[:space:]]+(BTP|ENTREPRISE)'
			--     THEN 'ANJARA ENTREPRISE'

			-- ANJARASOA variations
			WHEN UPPER(supplier) ~ 'ANJARASOA[[:space:]]+NILAINA[[:space:]]+B[EÉ]N[EÉ]DICTE'
			    THEN 'ANJARASOA NILAINA BENEDICTE'

			-- ADID variations
			WHEN UPPER(supplier) ~ '(ASSOCIATION[[:space:]]+)?ADID'
			    THEN 'ADID'

			-- AMPELA MITRAOKE variations
			WHEN UPPER(supplier) ~ '(ASSOCIATION[[:space:]]+)?AMPELA[[:space:]]*MITRAOKE'
			    OR UPPER(supplier) ~ 'AMPELAMITRAOKE'
			    THEN 'AMPELA MITRAOKE'
				
			-- LIANTSOA variations
			WHEN UPPER(supplier) ~ 'ASSOCIATION[[:space:]]+LIANTSOA([[:space:]]+FIANARANTSOA)?'
			    THEN 'ASSOCIATION LIANTSOA'

			-- VONJY variations
			WHEN UPPER(supplier) ~ 'ASSOCIATION[[:space:]]+VONJY[[:space:]]+I[VIvi]([[:space:]]+FAMPANDROSOANA[[:space:]]+MIRINDRA)?'
			    THEN 'ASSOCIATION VONJY IV'

			-- YOUNG PROGRESS variations
			WHEN UPPER(supplier) ~ 'ASSOCIATION[[:space:]]+YOUNG[[:space:]]+PROGRESS([[:space:]]+MADAGASCAR)?'
			    THEN 'ASSOCIATION YOUNG PROGRESS'

			-- ARO variations
			WHEN UPPER(supplier) ~ 'ASSURANCE[S]?[[:space:]]+ARO'
			    THEN 'ASSURANCES ARO'

			-- ATW variations
			WHEN UPPER(supplier) ~ 'ATW([[:space:]]+(CONSULTANTS[[:space:]]+)?MADAGASCAR)?'
			    THEN 'ATW MADAGASCAR'

			-- BECOM variations
			WHEN UPPER(supplier) ~ 'BECOM([[:space:]]+EDITIONS[[:space:]]+ET[[:space:]]+COMMUNICATION)?'
			    THEN 'BECOM'

			-- BIODEV variations
			WHEN UPPER(supplier) ~ 'BIODEV([[:space:]]+MADAGASCAR[[:space:]]+CONSULTING)?'
			    THEN 'BIODEV'
				
			-- BRGM variations
			WHEN UPPER(supplier) ~ 'BUREAU DE RE(S|CH)ERCHES G[EÉ]OLOGIQUES ET(/T)? MINI[EÈ]RES \(BRGM\)'
			    THEN 'BUREAU DE RECHERCHES GEOLOGIQUES ET MINIERES (BRGM)'

			-- BHR variations
			WHEN UPPER(supplier) ~ 'BUREAU[[:space:]]+D[''[:space:]]*[EÉ]TUDES[[:space:]]+BHR'
			    THEN 'BUREAU D''ETUDES BHR'

			-- ECOTRAM variations
			WHEN UPPER(supplier) ~ '(BUREAU[[:space:]]+D[[:space:]]+ETUDES[[:space:]]+)?ECOTRAM'
			    THEN 'ECOTRAM'

			-- ECS variations
			WHEN UPPER(supplier) ~ 'BUREAU[[:space:]]+D[[:space:]]+ETUDES[[:space:]]+ECS[O]?'
			    THEN 'BUREAU D ETUDES ECS'

			-- CEEXI variations
			WHEN UPPER(supplier) ~ 'CABINET D.*ETUDES ENVIRONNEMENTALES ET D.*EXPERTISE INDUSTRIELLE \(CEEX[IL]\)'
				OR UPPER(supplier) ~ '\yCEEXL\y'
			    THEN 'CABINET D''ETUDES ENVIRONNEMENTALES ET D''EXPERTISE INDUSTRIELLE (CEEXL)'

			-- CABINET MANISA variations
			WHEN UPPER(supplier) ~ 'CABINET[[:space:]]+MANISA(\(MALAGASY[[:space:]]+ASSOCIATES[[:space:]]+FOR[[:space:]]+NUMERICAL[[:space:]]+INFORMATION[[:space:]]+AND[[:space:]]+STATISTICAL[[:space:]]+ANALYSIS\))?'
			    THEN 'CABINET MANISA'

			-- CABINET MPANAZAVA variations
			WHEN UPPER(supplier) ~ 'CABINET[[:space:]]+MPANAZAVA([[:space:]]+AUDIT[[:space:]]+ET[[:space:]]+CONSEIL[[:space:]]+EN[[:space:]]+GESTION)?'
			    THEN 'CABINET MPANAZAVA'

			-- CABINET RANDRIAMAROSOLO variations
            WHEN UPPER(supplier) ~ '\yCABINET\s+RANDRIAMAROSOLO?(\s+&\s+VISIO\s+DESIGN)?\y'
                THEN 'CABINET RANDRIAMAROSOLO'

			-- CABINET SPROGES variations
            WHEN UPPER(supplier) ~ '\yCABINET\s+SPROGESS?\y'
                THEN 'CABINET SPROGES'

			-- CBL REPRO MADA variations
            WHEN UPPER(supplier) ~ '\yCBL\s+REPRO\s*MADA\y'
                THEN 'CBL REPRO MADA'

			-- CEEXI variations
            WHEN UPPER(supplier) ~ '\y(CABINET\s+D[''´`'']ETUDES\s+ENVIRONNEMENTALES\s+ET\s+D[''´`'']EXPERTISE\s+INDIVIDUELLE\s*\(CEEXI\)|CEEXI)\y'
                THEN 'CABINET D''ETUDES ENVIRONNEMENTALES ET D''EXPERTISE INDIVIDUELLE (CEEXI)'

			-- CIMELTA variations
            WHEN UPPER(supplier) ~ '\yCIMELTA(\s+MADAGASCAR)?\y'
                THEN 'CIMELTA'

			-- CJIC variations
            WHEN UPPER(supplier) ~ '\y(CJIC-CHINA\s+JIANGXI\s+INTERNATIONAL\s+ECONOMIC\s+AND\s+TECHNICAL\s+COOPERATION\s+CO\.?LTD|CJICI)\y'
                THEN 'CHINA JIANGXI INTERNATIONAL ECONOMIC AND TECHNICAL COOPERATION CO. LTD (CJIC)'
			
			-- COGECAB variations
            WHEN UPPER(supplier) ~ '\yCOGECAB(\s+SARLU)?\y'
                THEN 'COGECAB'
				
			-- CPCS TRANSCOM variations
            WHEN UPPER(supplier) ~ '\yCPCS\s+TRANSCOM\s+INT?\.?\s+LIMITED\y'
                THEN 'CPCS TRANSCOM INTERNATIONAL LIMITED'

			-- DELTA ASSOCIE variations
            WHEN UPPER(supplier) ~ '\yDELTA\s+ASSOCI[ÉE]S?\y'
                THEN 'DELTA ASSOCIE'
            
			-- DIRICKX variations
            WHEN UPPER(supplier) ~ '\yDIRICKX(\s+GUARD)?\y'
                THEN 'DIRICKX'

            -- DUAL TEK variations
            WHEN UPPER(supplier) ~ '\yDUAL\s*TEK\y'
                THEN 'DUAL TEK'

            --- DUO TECH variations
            WHEN UPPER(supplier) ~ '\yDUO\s*TECH\y'
                THEN 'DUO TECH'

            -- DUO TECH variations
            WHEN UPPER(supplier) ~ '\yDUO\s*TECH\y'
                THEN 'DUO TECH'

            -- DUPLI SERVICE variations
            WHEN UPPER(supplier) ~ '\yDUPLI\s*SERVICE\y'
                THEN 'DUPLI SERVICE'
            
			-- EGS SOARAFITRA variations
            WHEN UPPER(supplier) ~ '\yEGS\s+SOARAFITRA(\s*\(RAKOTONDRAMANANTSOA\s+JULES\))?\y'
                THEN 'EGS SOARAFITRA'

            -- ELECTRONICS APPLICATIONS SYSTEM SERVICE variations
            WHEN UPPER(supplier) ~ '\y(ELECTRONICS\s+APPLICATIONS\s+SYSTEM[S]?\s+SERVICE[S]?\s*[_()]*\s*EA2S|EA2S)\y'
                THEN 'ELECTRONICS APPLICATIONS SYSTEMS SERVICES (EA2S)'

            -- E MENDRIKA variations
            WHEN UPPER(supplier) ~ '\yE\.?\s*MENDRIKA\y'
                THEN 'E MENDRIKA'

            -- ENTIC variations
            WHEN UPPER(supplier) ~ '\yENTIC(\s+MADAGASCAR)?\y'
                THEN 'ENTIC'

            -- ENTREPRISE E ASA variations
            WHEN UPPER(supplier) ~ '\y(ENTREPRISE\s+)?E\s+ASA\y'
                THEN 'ENTREPRISE E ASA'

            -- EBTP variations
            WHEN UPPER(supplier) ~ '\y(ENTREPRISE\s+)?E\.?B\.?T\.?P\y'
                THEN 'EBTP'

            -- ENTREPRISE HASINA variations
            WHEN UPPER(supplier) ~ '\yENTREPRISE\s+HASINA(\s*\(VANOHASINA\s+FIHAROA\s+ELISIANE\))?\y'
                THEN 'ENTREPRISE HASINA'

            -- SECOGEM variations
            WHEN UPPER(supplier) ~ '\y(ENTREPRISE\s+)?SECOGEM\y'
                THEN 'SECOGEM'

            -- ENTREPRISE TINA EX MORA PRIX variations
            WHEN UPPER(supplier) ~ '\yENTREPRISE\s+"?TINA\s+EX[-\s]+MORA\s+PRIX"?\y'
                THEN 'ENTREPRISE TINA EX MORA PRIX'

           	-- ERNST & YOUNG variations
            WHEN UPPER(supplier) ~ '\yERNST[[:space:]]+(&[[:space:]]+)?YOUNG(\s+(AUDIT[[:space:]]*–?[[:space:]]*CONSEIL|MADAGASCAR))?\y'
                OR UPPER(supplier) ~ '\yERNEST[[:space:]]+(&[[:space:]]+)?YOUNG(\s+(AUDIT[[:space:]]*–?[[:space:]]*CONSEIL|MADAGASCAR))?\y'
                THEN 'ERNST & YOUNG'

            -- ERIC RAKOTO ANDRIANTSILAVO variations
            WHEN UPPER(supplier) ~ '\yERIC\s+RAKOTO[-\s]ANDRIANTSILAVO\y'
                THEN 'ERIC RAKOTO ANDRIANTSILAVO'

            -- ETECH variations
            WHEN UPPER(supplier) ~ '\yETECH([[:space:]]+CONSULTING)?\y'
                THEN 'ETECH'

            -- ETS MITSINJO variations
            WHEN UPPER(supplier) ~ '\yETS\s+MITSINJO([[:space:]]*-\s*RASOARINIAINA\s+BODOVELO)?\y'
                THEN 'ETS MITSINJO'

            -- EC PLUS variations
            WHEN UPPER(supplier) ~ '\y(E[[:space:]]*T[[:space:]]*U[[:space:]]*D[[:space:]]*E[[:space:]]*S[[:space:]]*E[[:space:]]*T[[:space:]]*C[[:space:]]*O[[:space:]]*N[[:space:]]*S[[:space:]]*E[[:space:]]*I[[:space:]]*L[[:space:]]*S[[:space:]]*P[[:space:]]*L[[:space:]]*U[[:space:]]*S|EC\s*PLUS)\y'
                THEN 'EC PLUS'

            -- FANOMEZANTSOA TENDRY variations
            WHEN UPPER(supplier) ~ '\yFANOMEZANTSOA\s+TENDRY(\s+INNOCENT)?\y'
                THEN 'FANOMEZANTSOA TENDRY'

            -- FTHM variations
            WHEN UPPER(supplier) ~ '\yFTHM(\s+CONSULTING(\s+ET\s+MBASC\s+CONSULTING)?)?\y'
                THEN 'FTHM CONSULTING'

            --
            WHEN UPPER(supplier) ~ '\yCONSTRUCT(ION|IONS)?\y' 
                THEN REGEXP_REPLACE(UPPER(TRIM(supplier)), '\yCONSTRUCT(ION|IONS)\y', 'CONSTRUCTIONS')
                
            -- Standardize common company suffixes
            ELSE REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        UPPER(TRIM(supplier))
                        , '\y(LTD|LIMITED)\y', 'LIMITED')
                    , '\s+', ' ')
        END AS normalized_supplier_name
    FROM wb_contract_awards
    WHERE 
		borrower_country = 'Madagascar'
		OR (
			borrower_country = 'Eastern and Southern Africa'
			AND supplier_country = 'Madagascar'
		)
	-- where project_id = 'P178566'
),
supplier_counts AS (
    SELECT 
        normalized_supplier_name,
        COUNT(DISTINCT supplier) as variant_count
    FROM normalized_suppliers
    GROUP BY normalized_supplier_name
)
SELECT
	-- ns.region,
	-- ns.borrower_country_code,
	-- ns.project_global_practice,
	-- ns.supplier_country_code,
	-- ns.review_type,
	-- ns.is_domestic_supplier,
	-- ns.fiscal_quarter,
	-- ns.contract_age_days
	
    TO_CHAR(CAST(ns.contract_signing_date AS TIMESTAMP), 'YYYY-MM-DD') AS contract_signing_date,
    ns.project_id,
	ns.borrower_country,
    ns.supplier_country,
    ns.supplier as original_supplier_name,
    ns.normalized_supplier_name as supplier,
	sc.variant_count,
    ns.wb_contract_number,
    NULLIF(TO_CHAR(ns.supplier_contract_amount_usd, '999,999,999,999.99'), '') as contract_amount,
    NULLIF(TO_CHAR(SUM(ns.supplier_contract_amount_usd) OVER (PARTITION BY ns.normalized_supplier_name), '999,999,999,999.99'), '') as supplier_total,
    ns.contract_description,
    ns.project_name,
    ns.borrower_contract_reference_number,
    ns.procurement_category,
    ns.procurement_method,
    ns.supplier_id,
    ns.fiscal_year,
    TO_CHAR(CAST(ns.as_of_date AS TIMESTAMP), 'YYYY-MM-DD') AS processed_at
FROM normalized_suppliers ns
LEFT JOIN supplier_counts sc ON sc.normalized_supplier_name = ns.normalized_supplier_name
ORDER BY
	-- supplier
	-- ns.borrower_country,
    SUM(ns.supplier_contract_amount_usd) OVER (PARTITION BY ns.normalized_supplier_name) DESC,
    ns.project_id,
    ns.supplier_contract_amount_usd DESC,
    ns.contract_signing_date;