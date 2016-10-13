import requests
import json
from requests.auth import HTTPBasicAuth
import hashlib
import unittest

url = 'https://upload.docs-sandbox.openprocurement.org'
register_suffix = '/register'
auth = HTTPBasicAuth('l.velychko.prozorro.gov.ua', 'ce9de9eb3c6a44459c5e8c24a871431d')
file_bytes = open('some_file.txt', 'rb').read()


def hash_file():
    hashed_to_md5 = hashlib.md5(file_bytes).hexdigest()
    return hashed_to_md5


def register_document():
    return requests.post(
        url + register_suffix,
        auth=auth,
        json={'data': {'hash': 'md5:' + hash_file()}}
    )


def upload_document(upload_url):
    return requests.post(
        upload_url,
        auth=auth,
        files={'file': file_bytes}
    )


class DocumentServiceTest(unittest.TestCase):

    def test_register(self):
        r = register_document()
        self.assertEqual(r.status_code, 201)

    def test_upload(self):
        register_response = register_document()
        register_json = json.loads(register_response.text)

        resp_from_upload_service = upload_document(register_json['upload_url'])
        upload_json = json.loads(resp_from_upload_service.text)

        self.assertEqual(
            resp_from_upload_service.status_code,
            200,
            msg="Document Upload Failed ({})".format(resp_from_upload_service.status_code)
        )
        self.assertNotIn('errorMessage', upload_json)
        self.assertEqual(upload_json['data']['hash'].split(':')[-1], hash_file())

    def test_get_document(self):
        register_response = register_document()
        register_json = json.loads(register_response.text)

        resp_from_upload_service = upload_document(register_json['upload_url'])
        upload_json = json.loads(resp_from_upload_service.text)

        get_doc_json = json.loads(resp_from_upload_service.text)
        get_url = get_doc_json['get_url']

        response_from_get = requests.get(get_url)
        self.assertEqual(response_from_get.status_code,
                         200,
                         msg="Fail To Get Document ({})".format(response_from_get.status_code)
                         )
        self.assertEqual(upload_json['data']['format'], 'text/plain')

    def test_upload_no_registartion(self):
        resp_from_upload_service = upload_document(url + '/upload')
        upload_json = json.loads(resp_from_upload_service.text)

        self.assertEqual(resp_from_upload_service.status_code,
                         200,
                         msg="Fail To Get Document ({})".format(resp_from_upload_service.status_code)
                         )
        self.assertNotIn('errorMessage', upload_json)

if __name__ == '__main__':
    unittest.main()
