function Get-EmojiSet {
    param(
        [Parameter(Mandatory)]
        [int]$StartIndex
    )

    # Base emoji start point (😀 U+1F600)
    $baseCode = 0x1F600

    # Generate exactly 64 sequential emojis
    $startCode = $baseCode + $StartIndex
    $EmojiSet = @()
    for ($i = 0; $i -lt 64; $i++) {
        $EmojiSet += [char]::ConvertFromUtf32($startCode + $i)
    }
    return $EmojiSet
}

function Encrypt-AES {
    param(
        [string]$PlainText,
        [string]$Key
    )

    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key.PadRight(32, '0').Substring(0, 32))
    $ivBytes = New-Object byte[] 16
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($ivBytes)

    $aes = [System.Security.Cryptography.AesManaged]::new()
    $aes.Key = $keyBytes
    $aes.IV = $ivBytes
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
    $encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

    return [Convert]::ToBase64String($ivBytes + $encryptedBytes)
}

function Decrypt-AES {
    param(
        [string]$CipherText,
        [string]$Key
    )

    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key.PadRight(32, '0').Substring(0, 32))
    $cipherBytes = [Convert]::FromBase64String($CipherText)
    
    $ivBytes = $cipherBytes[0..15]
    $actualCipherBytes = $cipherBytes[16..($cipherBytes.Length - 1)]

    $aes = [System.Security.Cryptography.AesManaged]::new()
    $aes.Key = $keyBytes
    $aes.IV = $ivBytes
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($actualCipherBytes, 0, $actualCipherBytes.Length)

    return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
}

function Encode-Emoji {
    param(
        [Parameter(Mandatory)]
        [string]$InputText,

        [string]$Key,  # If provided, encrypts with AES

        [int]$t = -1  # Default to -1 so that time-based encryption isn’t triggered by default
    )

    # 1) Determine StartIndex
    $StartIndex = Get-Random -Minimum 1 -Maximum 64
    $EmojiSet = Get-EmojiSet -StartIndex $StartIndex

    # 2) Encrypt if needed
    if ($Key) {
        $InputText = Encrypt-AES -PlainText $InputText -Key $Key
    } elseif ($t -ge 0 -and $t -le 9) {
        $currentMinute = (Get-Date).Minute
        $minuteKey = "$(($currentMinute - ($currentMinute % 10)) + $t)"
        $InputText = Encrypt-AES -PlainText $InputText -Key $minuteKey
    }

    # 3) Convert to Base64
    $Base64Text = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($InputText))

    # 4) Convert Base64 to Emoji Encoding
    $Base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    $EncodeMap = @{}
    for ($i = 0; $i -lt 64; $i++) { 
        $EncodeMap[$Base64Chars[$i]] = $EmojiSet[$i] 
    }

    $EncodedText = ""
    $markerEmoji = $EmojiSet[0]
    $EncodedText += $markerEmoji + $markerEmoji  # Start Index Marker

    foreach ($char in $Base64Text.ToCharArray()) {
        if ($char -eq "=") {
            $EncodedText += $EmojiSet[($EmojiSet.Count - 1)]  # Stealth Padding
        } else {
            $EncodedText += $EncodeMap[$char]
        }
    }

    return $EncodedText
}


function Decode-Emoji-Base {
    param(
        [Parameter(Mandatory)]
        [string]$EncodedText,

        # Optional key; if not provided, no AES decryption is performed
        [Parameter(Mandatory=$false)]
        [string]$Key
    )

    $clusterPositions = [System.Globalization.StringInfo]::ParseCombiningCharacters($EncodedText)
    if ($clusterPositions.Count -lt 3) {
        throw "Encoded text is too short or has an invalid format!"
    }
    
    # Get the two identical markers that indicate the start of the encoding.
    $marker1 = $EncodedText.Substring($clusterPositions[0], $clusterPositions[1] - $clusterPositions[0])
    $marker2 = $EncodedText.Substring($clusterPositions[1], $clusterPositions[2] - $clusterPositions[1])

    if ($marker1 -ne $marker2) {
        throw "Invalid start marker!"
    }

    # Derive the StartIndex based on the marker emoji.
    $baseCode = 0x1F600
    $StartIndex = [char]::ConvertToUtf32($marker1, 0) - $baseCode
    $EmojiSet = Get-EmojiSet -StartIndex $StartIndex

    $Base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    $DecodeMap = @{}
    for ($i = 0; $i -lt 64; $i++) {
        $DecodeMap[$EmojiSet[$i]] = $Base64Chars[$i]
    }

    $Base64Output = ""
    for ($posIndex = 2; $posIndex -lt $clusterPositions.Count; $posIndex++) {
        $startPos = $clusterPositions[$posIndex]
        $length = if ($posIndex -lt $clusterPositions.Count - 1) {
            $clusterPositions[$posIndex + 1] - $startPos
        } else {
            $EncodedText.Length - $startPos
        }
        $emoji = $EncodedText.Substring($startPos, $length)

        if ($emoji -eq $EmojiSet[($EmojiSet.Count - 1)]) {
            $Base64Output += "="
        } else {
            $Base64Output += $DecodeMap[$emoji]
        }
    }

    # Always convert from Base64 first.
    $DecodedFromBase64 = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64Output))
    
    # If a key is provided, decrypt the Base64-decoded text; otherwise, return it directly.
    if ([string]::IsNullOrEmpty($Key)) {
        return $DecodedFromBase64
    } else {
        return Decrypt-AES -CipherText $DecodedFromBase64 -Key $Key
    }
}


function Decode-Emoji-Static {
    param(
        [Parameter(Mandatory)]
        [string]$EncodedText,

        [Parameter(Mandatory)]
        [string]$Key
    )

    return Decode-Emoji-Base -EncodedText $EncodedText -Key $Key
}

function Decode-Emoji-Time {
    param(
        [Parameter(Mandatory)]
        [string]$EncodedText,

        [Parameter(Mandatory)]
        [int]$t  # Renamed for stealth
    )

    # 1) Get the current system minute
    $currentMinute = (Get-Date).Minute
    $expectedLastDigit = $t

    # 2) Validate that the last digit matches
    if (($currentMinute % 10) -ne $expectedLastDigit) {
    }

    # 3) Derive the AES key from the current time
    $minuteKey = "$(($currentMinute - ($currentMinute % 10)) + $t)"

    # 4) Proceed with decryption using the validated key
    return Decode-Emoji-Base -EncodedText $EncodedText -Key $minuteKey
}


function Encode-inEmoji {

  [CmdletBinding()]
  param (
      [Parameter(Mandatory=$true)]
      $string,

      [Parameter(Mandatory=$false)]
      $emoji = '😈',

      [Parameter(Mandatory=$false)]
      $key
  )

  if ($key) {$string = Encrypt-AES -PlainText $string -key $key}

  $selectors = @([char]0xFE00..[char]0xFE0F)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
  $binary = ($bytes | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }) -join ''
  $encoded = $emoji
  for ($i = 0; $i -lt $binary.Length; $i += 4) {
      $nibble = [Convert]::ToInt32($binary.Substring($i, 4), 2)
      $encoded += $selectors[$nibble]
  }
  set-clipboard -Value $encoded
}


function Decode-inEmoji {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$key
    )

    # UTF-8 encoding without BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    
    # Get the encoded string from the clipboard
    $encoded = Get-Clipboard
    if (-not $encoded) {
        Write-Error "Clipboard is empty. Run encodeEmojiKey first."
        return
    }
    if ($encoded.Length -lt 1) {
        Write-Error "Clipboard contains insufficient data."
        return
    }

    # Determine the emoji length (1 or 2 code units)
    $firstChar = $encoded[0]
    if ([char]::IsHighSurrogate($firstChar)) {
        $emojiLength = 2
    } else {
        $emojiLength = 1
    }

    # Check if there are selectors after the emoji
    if ($encoded.Length -le $emojiLength) {
        Write-Error "No selectors found. Clipboard should contain emoji + selectors."
        return
    }

    # Extract the selectors
    $selectorsInput = $encoded.Substring($emojiLength)

    # Convert selectors back to binary (each selector represents 4 bits)
    $binary = ''
    for ($i = 0; $i -lt $selectorsInput.Length; $i++) {
        $selectorValue = [int][char]$selectorsInput[$i] - 0xFE00
        if ($selectorValue -lt 0 -or $selectorValue -gt 15) {
            Write-Error "Invalid selector found: $($selectorsInput[$i])"
            return
        }
        $binary += [Convert]::ToString($selectorValue, 2).PadLeft(4, '0')
    }

    # Ensure binary length is a multiple of 8 (for byte conversion)
    if ($binary.Length % 8 -ne 0) {
        Write-Error "Binary data is incomplete. Length: $($binary.Length)"
        return
    }

    # Convert binary string to byte array
    $bytes = for ($i = 0; $i -lt $binary.Length; $i += 8) {
        [Convert]::ToInt32($binary.Substring($i, 8), 2)
    }

    # Decode bytes to string and filter to ASCII characters
    $keyDecoded = $utf8NoBom.GetString($bytes)
    $keyCleaned = ($keyDecoded.ToCharArray() | Where-Object { [int]$_ -lt 128 }) -join ''
    if ($key){$keyCleaned = Decrypt-AES -CipherText $keyCleaned -Key $key}
    Write-Output $keyCleaned
}
