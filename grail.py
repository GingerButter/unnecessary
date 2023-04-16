import json
import socket


try:
    HOST = "3.13.39.253"
    PORT = 53666
except (IndexError, ValueError):
    print("?")
    exit(1)


def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.connect((HOST, PORT))
        s = 'h'*116
        request = "{" + '\"code\": \"' + s + '\"}'
        print(request)
        sock.sendall(request.encode())
        while True:
            container = bytearray()
            l = 0
            while True:
                data = bytearray(sock.recv(4096))
                # print(data)
                container.extend(data)
                # print(container)
                if len(container) == l: break
                else: l = len(container)
            print(container.decode())
            break


if __name__ == '__main__':
    main()
