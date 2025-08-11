import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../models/voice_data.dart';

/// 语音录制页面
class VoiceRecordingPage extends StatefulWidget {
  const VoiceRecordingPage({super.key});

  @override
  State<VoiceRecordingPage> createState() => _VoiceRecordingPageState();
}

class _VoiceRecordingPageState extends State<VoiceRecordingPage>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _recognizedText = '';
  String _lastWords = '';
  double _confidence = 0.0;

  // 录音相关
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  int _recordingDuration = 0; // 秒
  
  // 动画控制器
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  /// 初始化语音识别
  void _initSpeech() async {
    try {
      _speech = stt.SpeechToText();
      _speechEnabled = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: true, // 启用调试日志
      );

      if (!_speechEnabled) {
        print('🎤 [Speech] 语音识别初始化失败');
        _showMessage('语音识别不可用，请检查权限设置');
      } else {
        print('🎤 [Speech] 语音识别初始化成功');
      }
    } catch (e) {
      print('🎤 [Speech] 初始化异常: $e');
      _speechEnabled = false;
      _showMessage('语音识别初始化失败: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// 初始化动画
  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
  }

  /// 语音状态回调
  void _onSpeechStatus(String status) {
    print('🎤 [Speech] Status: $status');
  }

  /// 语音错误回调
  void _onSpeechError(dynamic error) {
    print('🎤 [Speech] Error: $error');
    setState(() {
      _isListening = false;
    });
    _stopAnimations();
  }

  /// 开始录音
  void _startListening() async {
    if (!_speechEnabled) {
      _showMessage('语音识别不可用，请检查麦克风和语音识别权限');
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _lastWords = '';
        _confidence = 0.0;
        _recordingStartTime = DateTime.now();
        _recordingDuration = 0;
      });

      // 开始录音计时
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = timer.tick;
          });
        }
      });

      // 开始动画
      _startAnimations();

      // 开始语音识别
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(minutes: 5), // 最长录音5分钟
        pauseFor: const Duration(seconds: 3), // 暂停3秒后停止
        partialResults: true, // 启用实时结果
        localeId: 'zh_CN', // 中文识别
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      print('🎤 [Speech] 开始语音识别');
    } catch (e) {
      print('🎤 [Speech] 开始录音失败: $e');
      _showMessage('开始录音失败: $e');
      setState(() {
        _isListening = false;
      });
      _stopAnimations();
      _recordingTimer?.cancel();
    }
  }

  /// 停止录音
  void _stopListening() async {
    await _speech.stop();
    _recordingTimer?.cancel();
    setState(() {
      _isListening = false;
    });
    _stopAnimations();
  }

  /// 语音识别结果回调
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _confidence = result.confidence;
      if (result.finalResult) {
        _recognizedText += _lastWords + ' ';
      }
    });
  }

  /// 开始动画
  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  /// 停止动画
  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
  }

  /// 保存录音
  void _saveRecording() async {
    if (_recognizedText.trim().isEmpty && _lastWords.trim().isEmpty) {
      _showMessage('没有识别到语音内容');
      return;
    }

    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${directory.path}/voices');
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }

      // 生成文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_$timestamp.txt'; // 暂时保存为文本文件
      final filePath = '${voiceDir.path}/$fileName';

      // 合并识别文本
      final finalText = (_recognizedText + _lastWords).trim();

      // 保存文本文件（模拟音频文件）
      final file = File(filePath);
      await file.writeAsString(finalText);

      // 创建语音数据
      final voiceData = VoiceData(
        name: fileName,
        filePath: filePath,
        size: finalText.length, // 使用文本长度作为大小
        duration: _recordingDuration * 1000, // 转换为毫秒
        transcription: finalText,
        createdAt: DateTime.now(),
      );

      // 返回结果
      if (mounted) {
        Navigator.of(context).pop(voiceData);
      }
    } catch (e) {
      print('🎤 [Save] Error: $e');
      _showMessage('保存失败：$e');
    }
  }

  /// 显示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 格式化录音时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音录制'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 显示语音识别状态
          if (!_speechEnabled)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.orange),
              onPressed: () => _showMessage('语音识别不可用，请检查权限'),
            ),
          if (_recognizedText.isNotEmpty || _lastWords.isNotEmpty)
            TextButton(
              onPressed: _saveRecording,
              child: const Text('保存'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 录音状态显示
              Expanded(
                flex: 2,
                child: _buildRecordingStatus(),
              ),
              
              // 识别文本显示
              Expanded(
                flex: 3,
                child: _buildRecognizedText(),
              ),
              
              // 录音控制按钮
              _buildRecordingControls(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建录音状态显示
  Widget _buildRecordingStatus() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 录音时长
        Text(
          _formatDuration(_recordingDuration),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _isListening ? Colors.red : Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        
        // 录音状态文本
        Text(
          _isListening ? '正在录音...' : '点击开始录音',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _isListening ? Colors.red : Colors.grey,
          ),
        ),
        
        // 置信度显示
        if (_isListening && _confidence > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '识别置信度: ${(_confidence * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  /// 构建识别文本显示
  Widget _buildRecognizedText() {
    final displayText = _recognizedText + _lastWords;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 6),
              Text(
                '识别文本',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                displayText.isEmpty ? '开始录音后，识别的文字将显示在这里...' : displayText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: displayText.isEmpty 
                      ? Theme.of(context).textTheme.bodySmall?.color
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建录音控制按钮
  Widget _buildRecordingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : Theme.of(context).primaryColor)
                          .withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: _isListening ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
