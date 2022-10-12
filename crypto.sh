#!/bin/bash

# Encrypt: ./crypto.sh -e receiver1.pub receiver2.pub receiver3.pub sender.priv <plaintext_file> <encrypted_file>
# Decrypt: ./crypto.sh -d receiver<#>.priv sender.pub <encrypted_file> <decrypted_file>

args=("$@")

if [ "$1" == "-e" ]; then

    echo "Encryption mode"

    # Generate random session key
    openssl rand 32 > symmetric_keyfile.key

    echo "session key generated"

    # Use random session key to encrypt file1
    openssl enc -aes-256-cbc -in "$6" -out file1.txt.enc -pbkdf2 -pass file:symmetric_keyfile.key

    echo "file encrypted"

    # Use receiver1.pub to encrypt session key. Encrypted key is symmetric.key.enc.1
    openssl pkeyutl -in symmetric_keyfile.key -out symmetric.key.enc.1 -inkey "$2" -pubin -encrypt

    echo "symmetric key encrypted by first receiver public key"

    # Use receiver2.pub to encrypt session key. Encrypted key is symmetric.key.enc.2
    openssl pkeyutl -in symmetric_keyfile.key -out symmetric.key.enc.2 -inkey "$3" -pubin -encrypt

    echo "symmetric key encrypted by second receiver public key"

    # Use receiver3.pub to encrypt session key. Encrypted key is symmetric.key.enc.3
    openssl pkeyutl -in symmetric_keyfile.key -out symmetric.key.enc.3 -inkey "$4" -pubin -encrypt

    echo "symmetric key encrypted by third receiver public key"

    # Sign encrypted file1 with sender's private key
    openssl dgst -sha256 -sign "$5" -out file1.txt.enc.sign file1.txt.enc

    echo "encrypted file signed by sender private key"

    # zip files we need: encrypted file1, three encrypted symmetric key, and one encrypted file signature
    zip "$7" file1.txt.enc symmetric.key.enc.1 symmetric.key.enc.2 symmetric.key.enc.3 file1.txt.enc.sign

    echo "files are zipped"
    
    # remove files generated
    rm symmetric_keyfile.key
    rm file1.txt.enc
    rm symmetric.key.enc.1
    rm symmetric.key.enc.2
    rm symmetric.key.enc.3
    rm file1.txt.enc.sign

else

    if [ "$1" == "-d" ]; then

    echo "Decryption mode"

    # unzip the zip file
    unzip "$4"

    echo "file unzipped"

    # verify signature
    openssl dgst -sha256 -verify "$3" -signature file1.txt.enc.sign file1.txt.enc

    echo "file verified"

    # decrypt the session key with receiver's private key

    # First line for $2 is receiver 1, second line for receiver 2, third line for receiver3

    openssl pkeyutl -in symmetric.key.enc.1 -out symmetric.key -inkey "$2" -decrypt ||
    openssl pkeyutl -in symmetric.key.enc.2 -out symmetric.key -inkey "$2" -decrypt ||
    openssl pkeyutl -in symmetric.key.enc.3 -out symmetric.key -inkey "$2" -decrypt

    echo "session key decrypted"

    # decrypt the text file with session key
    openssl enc -aes-256-cbc -d -in file1.txt.enc -out "$5" -pbkdf2 -pass file:symmetric.key
    
    echo "file decrypted"

    # remove files generated
    rm symmetric.key
    rm file1.txt.enc
    rm file1.txt.enc.sign
    rm symmetric.key.enc.1
    rm symmetric.key.enc.2
    rm symmetric.key.enc.3

    else

        echo "Error for selection. Use -e/-d for Encryption/Decryption"

    fi

fi