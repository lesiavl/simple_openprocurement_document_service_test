#!/usr/bin/env python
# -*- coding: utf-8 -*-


*** Settings ***
Library  Collections
Library  String
Library  RequestsLibrary
Library  HttpLibrary.HTTP
Library  OperatingSystem
Library  service_document_service.py


*** Variables ***
${url}              https://upload.docs-sandbox.openprocurement.org
${register_uri}     /register
${auth}


*** Test Cases ***
Можливість зареєструвати завантаження документа
  ${hash}=  Дістати хеш із файла
  ${register_resp}=  Зареєструвати завантаження документа  ${hash}
  Should Be Equal As Integers  ${register_resp.status_code}  201


Можливість завантажити документ
  ${hash}=  Дістати хеш із файла
  ${register_resp}=  Зареєструвати завантаження документа  ${hash}
  ${upload_url}=  Get JSON value  ${register_resp.text}  /upload_url

  ${upload_resp}=  Завантажити документ  ${upload_url}
  Should Be Equal As Integers  ${upload_resp.status_code}  200

  ${hash_from_response}=  Get JSON value  ${upload_resp.text}  /data/hash
  Should Be Equal As Strings  "md5:${hash}"  ${hash_from_response}


Можливість отримати посилання документ
  ${hash}=  Дістати хеш із файла
  ${register_resp}=  Зареєструвати завантаження документа  ${hash}
  ${upload_url}=  Get JSON Value  ${register_resp.text}  /upload_url

  ${upload_resp}=  Завантажити документ  ${upload_url}
  Should Be Equal As Integers  ${upload_resp.status_code}  200

  ${upload_resp_format}=  Get JSON Value  ${upload_resp.text}  /data/format
  Should Be Equal As Strings  ${upload_resp_format}  "text/plain"


Можливість завантажити документ без попередньої реєстрації
  ${upload_resp}=  Завантажити документ  ${url}/upload
  Should Be Equal As Integers  ${upload_resp.status_code}  200


*** Keywords ***
Дістати хеш із файла
  Create File  foobar.txt  content=foobar
  ${file_data}=  Get File  foobar.txt
  ${hash_for_upload}=  Hash File  ${file_data}
  [Return]  ${hash_for_upload}


Зареєструвати завантаження документа
  [Arguments]  ${hash_for_upload}
  ${auth}=  Create List  [***  ***]
  ${headers}=  Create Dictionary  Content-Type=application/json
  ${hash}=  Create Dictionary  hash=md5:${hash_for_upload}
  ${hashed}=  Create Dictionary  data=${hash}

  Create Session  register  ${url}  headers=${headers}  auth=${auth}  verify=False
  ${resp}=  POST request  register  ${register_uri}  data=${hashed}
  [Return]  ${resp}


Завантажити документ
  [Arguments]  ${upload_url}
  ${auth}=  Create List  [***  ***]

  Create File  foobar.txt  content=foobar
  ${file_data}=  Get File  foobar.txt
  ${files}=  Create Dictionary  file=${file_data}

  ${suffix_for_upload}=  Remove String  ${upload_url}  ${url}
  ${suffix_for_upload}=  Remove String  ${suffix_for_upload}  "

  Create Session   upload  ${url}  auth=${auth}   verify=False

  ${upload_resp}=  POST Request  upload  ${suffix_for_upload}  files=${files}
  [Return]  ${upload_resp}


Отримати посилання на документ
  [Arguments]  ${get_url}
  Create Session  get  /get  auth=${auth}  verify=False
  ${upload_resp}=  GET Request  get  ${get_url}
  [Return]  upload_resp
