# AES Encryption (CBC & CTR Modes)

Minimal implementation of AES supporting CBC and CTR modes.

---

## Features

* AES-128
* EBC (Electronic Code Book)
* CBC (Cipher Block Chaining)
* CTR (Counter Mode)

---

## Modes

### CBC

* Requires Initialization Vector (IV)
* Each block depends on previous ciphertext
* Not parallelizable

### CTR

* Uses nonce + counter
* Acts like a stream cipher
* Parallelizable and fast

---

## Usage

### CBC Mode

encrypt(key, plaintext, iv)

### CTR Mode

encrypt(key, plaintext, nonce)


---

### Verification 
Verified using a simple testbench based on standard NSIT examples
