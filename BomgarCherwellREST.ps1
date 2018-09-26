#Set up variables
#Today's Date
$dateChatsEnded = Get-Date -Format yyyy-MM-dd
#URI for Bomgar
$uri = "https:/bomgarexample.com"
#URI for CSM
$csmUri = "https://cherwellexample.cherwellondemand.com/CherwellApi"
#Bomgar API Client ID
$clientID = "...GUID..."
#Cherwell REST API Client ID
$csmClientID = "...GUID..."
#Username with Rest API Access
$csmuser = "SA_Example"
#Password for above username
$csmpass = "Don't store your passwords in plan text..."
#Secret for Bomgar API access
$secret = "Don't store this in plan text either..."
#Incident Object ID from Cherwell Blueprint
$incidentObjectID = "...GUID..."
#Journal.RemoteSupportHistory Object ID from Cherwell Blueprint
$journalRemoteObjectID = "...GUID..."
#Relationship ID from Cherwell Blueprint (Incident->Journal.RemoteSupportHistory)
$csmRelationshipID = "...GUID..."
#Field ID for the session key on the Journal.RemoteSupportHistory from a Cherwell blueprint
$keyFieldID = "...GUID..."
#Authentication pair for Bomgar API, converted to Base64 string, and then an auth header value
$pair = "${clientID}:${secret}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
#Variable to hold the headers for Cherwell API calls
$csmheaders = @{ 'Content-Type' = 'application/x-www-form-urlencoded' }
#Variable to hold the headers for Bomgar API Calls
$headers = @{ 'Authorization' = $basicAuthValue; 'Content-Type' = 'application/x-www-form-urlencoded' }
#Variable for the Bomgar body values
$body = @{ 'grant_type' = 'client_credentials' }
#Variable for the Cherwell body values, and example getting a Cherwell token.
$csmbody = @{
        'grant_type'= "password";
        'client_id'= $csmClientID;
        'username'= $csmuser;
        'password'= $csmpass;
        }
$csmfulltoken = Invoke-RestMethod "$csmUri/token?auth_mode=LDAP&api_key=$csmClientID" -Method Post -Body $csmbody -Headers $csmheaders -ContentType 'application/json' -UseBasicParsing
#Stripping to the auth token, for use in subsequent calls
$csmtoken = ($csmfulltoken | select access_token).access_token
$csmauthtoken = "Bearer $csmtoken"
#Set up authorization header for CSM
$csmheaders = @{ 'Authorization' = $csmauthtoken; }

# Call to request the oAuth token for Bomgar
$fulltoken = Invoke-WebRequest -Uri "$uri/oauth2/token" -Method Post -Headers $headers -Body $body -UseBasicParsing
# Parse the returned token JSON
$token = ($fulltoken.Content | ConvertFrom-Json | Select access_token).access_token
$authtoken = "Bearer $token"

# Get Bomgar session list for the date specified
$headers = @{ 'Authorization' = $authtoken; 'Content-Type' = 'application/x-www-form-urlencoded' }
$body = @{ 'generate_report' = 'SupportSessionListing'; 'end_date' = $dateChatsEnded; 'duration' = '0' }
$sessionlist = Invoke-WebRequest -Uri "$uri/api/reporting" -Method Post -Headers $headers -Body $body -UseBasicParsing

#Using this example, you would need to parse down the returned XML to individual External Keys (Incident Numbers)
#Remember that this process will rely on the Incient Number being passed to Bomgar during chat initiation, and the LSID of the resulting chat session.

#...


#Continuing with the example, you could eventually set up the API call to Cherwell, to create the Journal.RemoteSupportHistory, on the Incident identified above.
#You may want to add some additional conditions to the script to prevent this creation for every record on every pass (so that incidents that already have a Journal.RemoteSupportHistory from this chat session, don't get more)
$csmbody = @{
            parentBusObId= $incidentObjectID;
            parentBusObRecId= "...REC ID OF INCIDENT TO CREATE AGAINST...";
            relationshipId= $csmRelationshipID;
            busObId= $journalRemoteObjectID;
            fields= ,@{
                dirty= "true";
                displayName= "ChatSessionID";
                fieldId= $keyFieldID;
                value="...The LSID parsed from the above..."
                };
            }

$journalRemoteSupportHistory = Invoke-RestMethod "$csmUri/api/V1/saverelatedbusinessobject" -Method Post -Headers $csmheaders -Body ($csmbody | ConvertTo-Json) -ContentType 'application/json' -UseBasicParsing
    
#Remember, this is not a complete solution. It is an example intended to illustrate:
# 1. Setting up necessary PowerShell parameters
# 2. Getting a token from Cherwell for subsequent API calls
# 3. Getting a token from Bomgar for subsequent API calls
# 4. An additional example of an API call to Bomgar, using PowerShell
# 5. An additional example of an API call to Cherwell, using PowerShell
#_____
#
# Also remember that you may need to add thigns to this example to facilitate basic connectivity. 
# For example, depending on the security policy of the machine on which you execute this, you may need to add code to ignore certificate warnings.
# On a final note, remember to use your Swagger pages for your Cherwell API to construct additional calls (using these examples as a building block)
# And remember to use your Bomgar API reference for information on how to construct API calls to pull or handle report data, if needed.