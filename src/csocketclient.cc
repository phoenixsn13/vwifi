#include <iostream> // cout
#include <cstdio> //perror

#include <arpa/inet.h> // INADDR_ANY
#include <unistd.h> // close
#include <assert.h> // assert

#include "csocketclient.h"
#include "tools.h"

using namespace std;

// ----------------- CSocketClient

CSocketClient::~CSocketClient()
{
	CSocket::Close();
}

CSocketClient::CSocketClient() : CSocket()
{
	Init();
}

CSocketClient::CSocketClient(TSocket type) : CSocket(type)
{
	Init();
}

void CSocketClient::Init()
{
	IsConnected=false;
	StopTheReconnect=false ;
}

bool CSocketClient::ConnectLoop()
{
	while ( ! StopTheReconnect )
	{
		if( Connect() )
			return true;
	}

	// The system asks to stop the reconnect
	return false;
}

bool CSocketClient::ConnectCore(struct sockaddr* server, size_t size_of_server)
{
	if( ! Configure() )
	{
		cerr<<"Error : CSocketClient::Connect : Configure"<<endl;
		return false;
	}

	if( ! connect(Master,server,size_of_server) )
	{
		IsConnected=true;

		return true;
	}

	perror("CSocketClient::Connect : connect");
	Close();
	sleep(2);

	return false;
}

ssize_t CSocketClient::Send(const char* data, ssize_t sizeOfData)
{
	if ( IsConnected ){

		return CSocket::Send(Master, data, sizeOfData);

	}
	return SOCKET_ERROR;
}

ssize_t CSocketClient::SendBigData(const char* data, TMinimalSize sizeOfData)
{
	if ( IsConnected ){
		return CSocket::SendBigData(Master, data, sizeOfData);
	}
	return SOCKET_ERROR;
}

ssize_t CSocketClient::Read(char* data, ssize_t sizeOfData)
{
	if ( IsConnected ){

		return CSocket::Read(Master, data, sizeOfData);

	}
	return SOCKET_ERROR;
}

ssize_t CSocketClient::ReadBigData(CDynBuffer* data)
{
	if ( IsConnected ){
		return CSocket::ReadBigData(Master, data);
	}
	return SOCKET_ERROR;
}

void CSocketClient::StopReconnect(){

	StopTheReconnect = true ;
}

// ----------------- CSocketClientINET

CSocketClientINET::CSocketClientINET() : CSocketClient(AF_INET) {}

void CSocketClientINET::Init(const char* IP, TPort port)
{
	Server.sin_family = AF_INET;
	Server.sin_addr.s_addr = inet_addr(IP);
	Server.sin_port = htons(port);
}

bool CSocketClientINET::Connect()
{
	return ConnectCore((struct sockaddr*) &Server, sizeof(Server));
}

int CSocketClientINET::GetID()
{
	struct sockaddr_in my_addr;

	socklen_t len = sizeof(my_addr);
	getsockname(Master, (struct sockaddr *) &my_addr, &len);

	return hash_ipaddr(&my_addr) ;
}

// ----------------- CSocketClientVHOST

CSocketClientVHOST::CSocketClientVHOST() : CSocketClient(AF_VSOCK) {}

void CSocketClientVHOST::Init(TPort port)
{
	Server.svm_family = AF_VSOCK;
	Server.svm_reserved1 = 0;
	Server.svm_port = port;
	Server.svm_cid = 2;
}

bool CSocketClientVHOST::Connect()
{
	return ConnectCore((struct sockaddr*) &Server, sizeof(Server));
}

int CSocketClientVHOST::GetID()
{
	return -1;
}
