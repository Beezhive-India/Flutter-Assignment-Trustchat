import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class VideoCallScreen extends StatefulWidget {
  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    initRenderers();
    _connectToSignalingServer();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _socket.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _startLocalStream();
  }

  Future<void> _startLocalStream() async {
    final mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = stream;
    _localStream = stream;
    await _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(config);
    _peerConnection?.onIceCandidate = (candidate) {
      _socket.emit('candidate', candidate.toMap());
    };
    _peerConnection?.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
    };

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _socket.on('offer', (data) async {
      await _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
      final answer = await _peerConnection?.createAnswer();
      await _peerConnection?.setLocalDescription(answer!);
      _socket.emit('answer', {'sdp': answer?.sdp, 'type': answer?.type});
    });

    _socket.on('answer', (data) async {
      await _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
    });

    _socket.on('candidate', (data) async {
      final candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
      await _peerConnection?.addIceCandidate(candidate);
    });

    final offer = await _peerConnection?.createOffer();
    await _peerConnection?.setLocalDescription(offer!);
    _socket.emit('offer', {'sdp': offer?.sdp, 'type': offer?.type});
  }

  void _connectToSignalingServer() {
    _socket = IO.io('http://your_server_ip:3000', <String, dynamic>{
      'transports': ['websocket'],
    });

    _socket.on('connect', (_) {
      print('Connected to signaling server');
    });

    _socket.on('disconnect', (_) {
      print('Disconnected from signaling server');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Video Call")),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(_localRenderer)),
          Expanded(child: RTCVideoView(_remoteRenderer)),
        ],
      ),
    );
  }
}
