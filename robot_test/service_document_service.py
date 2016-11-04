import hashlib


def hash_file(file_bytes):
    return hashlib.md5(file_bytes).hexdigest()

