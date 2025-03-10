🔥 Stealthy PowerShell Encoding: Emojis, AES, and Time-Locked Secrets
Part 1/2

I've always loved combining creativity with security, and recently I found a fascinating way to do it: using emojis as an encoding method in PowerShell scripts. Emojis are everywhere—text messages, social media, emails—and they're rarely seen as suspicious. I thought, why not leverage their ubiquity for stealthy data transmission? In this blog, I'll walk through exactly how I combined emoji encoding with AES encryption and an intriguing time-lock mechanism to create secure, covert, and highly creative methods for data hiding. In part 2 is where things get really interesting. Instead of just using emojis to encode/encrypt data I am going to teach you how to modify and hide data INSIDE the emojis themselves that remain persistent even on sites like twitter. You will have emojis that are indiscernible from just regular ones but they each hide a secret of their own. 

🚀 Why Emoji Encoding?

Traditional encoding methods like Base64 are commonly recognized and detected by security systems (such as AMSI and antivirus solutions). This often leads to scripts being flagged or intercepted. Emojis, on the other hand, appear innocent and blend seamlessly into regular digital communications. They offer:

Innocuous Appearance: Emojis naturally fit within modern text communications, reducing suspicion.

Complexity and Diversity: Their diverse and multi-byte structure makes it harder for automated security tools to detect.

Novelty: Most security systems aren't tuned to recognize emojis as threats.

Creativity and Fun: Using emojis turns an otherwise mundane process into an engaging and creative challenge.

Subtlety in Data Exfiltration: Emojis can be discreetly embedded in regular chat or social media traffic without raising suspicion.

🚀 Solving the Unicode Emoji Puzzle

Initially, I encountered an issue where emojis were incorrectly parsed during the encoding process. Emojis are composed of "surrogate pairs," meaning they're often represented by two characters internally, even though they look like a single character. This caused some significant headaches:

The initial approach incorrectly assumed each emoji was just one character, causing garbled data.
😊    - original emoji
� �  - emoji when you separate the upper and lower surrogate

Surrogate pairs needed to be handled carefully to ensure accurate encoding and decoding.

Explained Simply: Imagine emojis as special characters that secretly require two separate letters to display correctly. If you only grab part of that "pair," your emoji becomes broken, and decoding fails. Once I realized emojis needed special treatment due to their internal representation, I fixed the problem by properly parsing each emoji as a complete unit.

This will become very important for Part 2
You can use the following snippet to get the unicode value for the pair of surrogates

```powershell
# Display surrogate pair codes for an emoji
$emoji = "😀"
$emoji.ToCharArray() | ForEach-Object { [int]$_ }

#output
55357
56832
```

🔹 Detailed Breakdown of the Functions

🛠 Get-EmojiSet

This function generates a list of 64 sequential emojis starting from a random index. A random starting point ensures unpredictability, meaning every encoding could start with a different emoji set.
This is to mirror the functionality of base64. There are 128 emojis in this set so if we pick a random number between 1-64 our encoding can be dynamic since we are just using 64 of them sequencely. 
We would just need to keep track of the starting index of the first emoji so we can properly decode it as well.

🔑 Encrypt-AES & Decrypt-AES

These functions securely encrypt and decrypt data using AES-256-CBC mode. AES encryption is a strong, widely-used method, ideal for securely encoding messages.
If we were to use just the encoding from above there is still always the chance someone could catch onto the pattern and decode it themselves. 
Encrypting with AES just means even if they do decode it they won't be able to get the plain text unless they know the password.

Encrypt-AES: Encrypts your plaintext into ciphertext using a provided key.
Decrypt-AES: Reverses this encryption process with the same key.

🔒 Encode-Emoji

Encodes your message into emojis. The function supports three different modes:
Emoji-only encoding: Simple obfuscation, no encryption.
AES Encryption with Static Key: Securely encrypts messages with a known key.
AES Encryption with Time Lock: Encrypts data with an AES key derived from the current time, ensuring messages are only decrypted at certain minutes.

🏁 The Emoji Start Marker

Remember how we said to properly decode this we would also need to know the starting index of the first emoji?
Well the first two identical emojis in an encoded message indicate the starting position of the emoji set used for encoding. Since there are many emojis, the position could start anywhere, making it harder to guess. For example:

😆😆😂🤣😜🤔

The "😆😆" tells the decoder exactly where to start decoding from the emoji alphabet. This way, we don't need to explicitly share the starting point separately which would be that random number between 1 and 64.
I actually decided on a random number between 1 and 63 so we wouldnt have to use a static "padding emoji"
What I mean by that is you know how sometimes base64 strings end with one or two equal [=] signs? Originally I was going to use "🛑" as the padding character. However by selecting a random number from a max of 63 instead of 64 
that means we can just use the next emoji in the sequence as the padding character instead, making it less noticable that we are again essentially just mirroring base64 encoding.

🔑 Decode-Emoji-Static & Decode-Emoji-Time

Two distinct decoding methods ensure flexibility and stealth:

Static Decoding uses a static key agreed upon beforehand. Which again just makes it so if they do decode it they wont have access to the plain text without a password.

Time-based Decoding generates an AES key based on the system time's last digit. It only works when the minute ends with the correct digit, adding an extra layer of stealth.
For this one to be honest I am just being a little extra.

🕒 How Time-Based AES Encryption Works

The -t parameter specifies the "unlock minute." To generate the AES key:

First, I take a cryptographic hash (like SHA256) of the first two emojis (the starting emojis) from the emoji set. This creates a base value unique to each encoding session.

Then, I append the chosen "time factor" (-t) to this hash, creating a unique key that ties encryption and decryption specifically to the system minute ending in that digit.
So hash of "😊😊" these to emojis + the time factor we decide [a number between 0-9] will essentially become the password.

For example, if you choose -t 2, the AES key is the hash of the two emojis plus the digit 2, meaning the ciphertext can only be decrypted when the current system minute is something like 1:02, 4:12, 9:22, etc. Decryption fails at any other minute, greatly enhancing security. So you have to run the decode function when the time on the system ends with a 2 or it will not decode it properly.

📡 Practical Real-World Usage

This emoji-AES encoding is useful in various cybersecurity applications:

Bypassing AMSI (Anti-Malware Scan Interface): Emojis can evade signature-based detection methods.

Red Team Engagements: Securely and covertly transmit commands or data.

Penetration Tests: Avoid automated detection by encoding sensitive scripts or payloads.

Secure Communications: Adding a time-based decryption window enhances operational security (OpSec).

🐱‍👤 Ethical and Responsible Use

As always, please use these methods ethically and responsibly. This is meant for security professionals and researchers to test and demonstrate weaknesses in systems and not for malicious activity.

📖 Final Thoughts & A Personal Request

This project showcases my favorite part about cybersecurity: creativity. It demonstrates how we can leverage ordinary elements, like emojis, in unconventional ways. 
If you found this helpful or interesting, please consider supporting my non-profit cat sanctuary, The Kitten Castle, where I rescue and provide therapy through the care of cats, 
especially for veterans. Your support means the world and helps ensure continued care for these animals.

Make sure you tune into part 2 where I show you how to indescretely modify the emojis themselves to hide data in a way you never thought possible, 
and the best part is it works on any platform where they emojis are commonly used 🤫
Stay ethical, keep hacking creatively, and never stop innovating! 🚀🐱‍💻🔥
