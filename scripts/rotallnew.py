def dencrypt(s: str,n: int = 13) -> str:
    out = ""
    for c in s:
        if "A" <= c <= "Z":
            out += chr(ord("A") + (ord(c) - ord("A") + n) % 26)
        elif "a" <= c <= "z":
            out += chr(ord("a") + (ord(c) - ord("a") + n) % 26)
        else:
            out += c
    return out


def main() -> None:
    s0 = input("Enter message: ")
    n = int(input("Enter the ROT number (if default case , enter 13): "))
    s1 = dencrypt(s0, n)
    print("Encryption:", s1)
    s2 = dencrypt(s1, n)
    print("Decryption: ", s2)


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    main()
