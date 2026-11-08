*** Settings ***
Library    SeleniumLibrary
Library    Collections
Library    RequestsLibrary


*** Variables ***
${BASE_URL}    https://rest.arbeitsagentur.de/jobboerse/jobsuche-service
${POSITION}    QA
${LOCATION}    Berlin
${FIELD}    


*** Test Cases ***
Send a normal request
    ${HEADER}=    Create Dictionary    X-API-Key=jobboerse-jobsuche
    ${params}=    Create Dictionary    was=${POSITION}    wo=${LOCATION}    #berufsfeld=${FIELD}

    ${getResponse}=    GET    ${BASE_URL}/pc/v6/jobs    headers=${HEADER}    params=${params}
    Set Global Variable    ${getResponse}
    Status Should Be    200    ${getResponse}
    Log    ${getResponse.json()}
    ${prettyJSON}=    Evaluate    json.dumps($getResponse.json(), indent=2, ensure_ascii=False)    modules=json
    Log    ${prettyJSON}

Get the reference numbers from the job search results
    ${referenznummern}=    Create List
    ${jobsDictionary}=    Set Variable    ${getResponse.json()}[ergebnisliste]
    FOR    ${job}    IN    @{jobsDictionary}
         Append To List    ${referenznummern}    ${job}[referenznummer]
    END
    Log    ${referenznummern}
    Set Global Variable    ${referenznummern}


Convert one code for all jobs
    ${referenznummernDecoded}=    Create List
    FOR    ${refnr}    IN    @{referenznummern}
        ${encoded}=    Evaluate    __import__('base64').b64encode($refnr.encode()).decode()
        Append To List    ${referenznummernDecoded}    ${encoded}
        Log    ${encoded}
    END
    Set Global Variable    ${referenznummernDecoded}
    log    ${referenznummernDecoded}
    

Send a detailed request
    ${getResponseDetailList}=    Create List    
    ${HEADER}=    Create Dictionary    X-API-Key=jobboerse-jobsuche
#    ${params}=    Create Dictionary    was=${POSITION}    wo=${LOCATION}    #berufsfeld=${FIELD}
    
    FOR    ${encoded}    IN    @{referenznummernDecoded}
        ${getResponseDetail}=    GET    ${BASE_URL}/pc/v4/jobdetails/${encoded}    headers=${HEADER}    #params=${params}
#       Status Should Be    200    ${getResponseDetail}
        Log    ${getResponseDetail.json()}
        Append To List    ${getResponseDetailList}    ${getResponseDetail.json()}
        Sleep    0.5s
    END
    Log    ${getResponseDetailList}
    Set Global Variable    ${getResponseDetailList}
 

For getting the URL

    ${listRelevantData}     Create List
    FOR     ${item}    IN    @{getResponseDetailList}
        ${stellenangebots}=    Get From Dictionary    ${item}    stellenangebotsTitel
        ${Company}=     Get From Dictionary    ${item}    firma
        Append To List     ${listRelevantData}    ${stellenangebots}
        Append To List     ${listRelevantData}    ${Company} 
    END
    Log    ${listRelevantData}

    

