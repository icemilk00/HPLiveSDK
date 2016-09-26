#ifndef _AUDIO_FRAMEENCODER_H_
#define _AUDIO_FRAMEENCODER_H_

extern "C"
{
#include <libavcodec/avcodec.h>
#include <libavutil/opt.h>
#include <libavutil/avstring.h>
#include <libswresample/swresample.h>
}
#include <unistd.h>

// 定义函数指针类型
typedef void (*PushDataCallBackHandler)(void *delegate, uint8_t *data,int size,unsigned int timestamp);
typedef int32_t (*PopCallBackHandler)(void *delegate, uint8_t *encodeBuffer, int bufferSize, int timeOut, int64_t *pts);
typedef void (*ClearCallBackHandler)(void *delegate);

class CAudioFrameEncoder
{
public:
    CAudioFrameEncoder();
    ~CAudioFrameEncoder();
    bool Init(int liSampleRate, int liChannels, int liBitRate, int aacType, void *delegate);

    void start();
    void run();
    void stop();
    void release();

private:
    bool EncodeAndPush(uint8_t* lpData, uint32_t liDataLen, unsigned int timestamp);

    bool initCodec();

    void saveAacFile();

    void savePcmFile(uint8_t* data, uint32_t length);
private:
    AVCodecID        m_codec_id;
    int              m_nSampleRate;
    int              m_nChannels;
    int              m_nBitRate;
    
    AVCodec*         m_pCodec;
    AVCodecContext*  m_pCodecCtx;

    AVFrame*         m_pFrame;
    AVPacket         m_packet;

    uint8_t*         m_samples;
    int              m_nSamplesSize;

    int              m_iAacType;

private:
    enum STATES{RUNNING = 0, STOPED = 1};
    pthread_t m_ThreadId;
    volatile STATES mState;
    volatile bool m_bStopped;

private:
    uint8_t * m_pPcmBuffer;
    uint32_t m_uPcmBufLen;

    
private:
    // 要实现回调的对象
    void *m_delegate;
public:
    //回调函数声明
    PushDataCallBackHandler audioEncoderPushAACData;
    PopCallBackHandler audioEncodertryPop;
    ClearCallBackHandler audioEncoderClear;
};

#endif

