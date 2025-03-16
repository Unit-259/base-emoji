
function Encode-inEmoji {

  [CmdletBinding()]
  param (
      [Parameter(Mandatory=$true)]
      $string,

      [Parameter(Mandatory=$false)]
      $emoji = '😈',

      [Parameter(Mandatory=$true)]
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
