# 🔐 Base-Emoji Encryption for PowerShell  

This project provides a **stealthy encoding & encryption system** using **emoji-based encoding**, **AES encryption**, and **optional time-locked decryption**.  

## 🚀 Features  
✅ **Emoji-based encoding** for obfuscation  
✅ **AES-256 encryption** with a static key or time-based key  
✅ **Stealthy time-locked decryption** (only decrypts at specific minutes)  
✅ **Supports three encoding modes** (Emoji-only, AES + Key, AES + Time)  

## ⚙️ Functions  

### 🔹 `Get-EmojiSet`  
Generates a **set of 64 sequential emojis** starting from a given index.  
```powershell
Get-EmojiSet -StartIndex 10
```

### 🔹 `Encrypt-AES`  
Encrypts a string using **AES-256-CBC** with a given key.  
```powershell
Encrypt-AES -PlainText "Secret Data" -Key "SuperSecure123"
```

### 🔹 `Decrypt-AES`  
Decrypts an **AES-256 encrypted string** with the correct key.  
```powershell
Decrypt-AES -CipherText "EncryptedBase64String" -Key "SuperSecure123"
```

### 🔹 `Encode-Emoji`  
Encodes a message using **emoji-based encoding**. Supports three modes:  

#### **🟢 Mode 1: Just Emoji Encoding (No Encryption)**  
```powershell
Encode-Emoji -InputText "Hello, world!"
```

#### **🟢 Mode 2: AES Encryption + Static Key**  
```powershell
Encode-Emoji -InputText "Super Secret" -Key "MySecurePass"
```

#### **🟢 Mode 3: AES Encryption + Time Lock**  
```powershell
Encode-Emoji -InputText "Time-Locked Secret" -t 2
```

### 🔹 `Decode-Emoji-Base`  
Core decoder function that converts **emoji-encoded data** back to **Base64**.  

### 🔹 `Decode-Emoji-Static`  
Decrypts a **Base-Emoji encoded AES message** using a **static key**.  
```powershell
Decode-Emoji-Static -EncodedText "😆😆😂🤣😜🤔" -Key "MySecurePass"
```

### 🔹 `Decode-Emoji-Time`  
Decrypts a **Base-Emoji encoded AES message** using a **time-based key**.  
- **Only works when the system time ends in the correct digit.**  
```powershell
Decode-Emoji-Time -EncodedText "😆😆😂🤣😜🤔" -t 2
```

## 📖 Learn More  
For a **deep dive** into the encoding process, **encryption details**, and **real-world use cases**, check out the **full blog post on PowerShellForHackers.com**! 🚀🔥
