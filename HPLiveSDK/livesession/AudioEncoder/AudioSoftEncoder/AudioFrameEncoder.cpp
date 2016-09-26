#include <pthread.h>
#include <unistd.h>

#include "AudioFrameEncoder.h"
#include <sys/time.h>
//#include "logUtil.h"
//#include "TimeUtil.h"
//#include "../util/DataPusher.h"
//#include "util/QueueManager.h"
//#include "../../../../../player/src/main/jni/ffmpeg/include/libavcodec/avcodec.h"
//#include "../../../../../player/src/main/jni/ffmpeg/include/libavutil/samplefmt.h"
//#include "../util/QueueManager.h"

#define LOGE(...)
#define LOGW(...)
#define LOGI(...)
#define RECORD_BUFFER_SIZE 4096

CAudioFrameEncoder::CAudioFrameEncoder()
{
    m_codec_id = AV_CODEC_ID_AAC;
    m_pCodecCtx = NULL;
    m_pFrame = NULL;

    m_samples = NULL;
    m_nSamplesSize = 0;

    m_pPcmBuffer = NULL;
    m_uPcmBufLen=0;

    m_bStopped = false;
    m_ThreadId ;//= -1;
}

CAudioFrameEncoder::~CAudioFrameEncoder()
{
    release();
}

//��ʼ��������
bool CAudioFrameEncoder::Init(int liSampleRate, int liChannels, int liBitRate, int aacType, void *delegate)
{
    m_nSampleRate = liSampleRate;
    m_nChannels = liChannels;
    m_nBitRate = liBitRate;
    m_iAacType = aacType;
    m_delegate = delegate;

    return true;
}

bool CAudioFrameEncoder::initCodec()
{
    avcodec_register_all();

    m_pCodec = avcodec_find_encoder(m_codec_id);
    
    if (!m_pCodec) {
        LOGW("CAudioFrameEncoder::Init Fail, Codec not found");
        return false;
    }

    m_pCodecCtx = avcodec_alloc_context3(m_pCodec);
    if (!m_pCodecCtx){
        LOGW("CAudioFrameEncoder::Init Fail, Could not allocate video codec context");
        return false;
    }

    m_pCodecCtx->codec_id = m_codec_id;
    m_pCodecCtx->sample_fmt = AV_SAMPLE_FMT_S16;
    m_pCodecCtx->sample_rate = m_nSampleRate;
    m_pCodecCtx->channels = m_nChannels;
    m_pCodecCtx->channel_layout = av_get_default_channel_layout(m_nChannels);
    m_pCodecCtx->bit_rate = m_nBitRate * 1000;
    m_pCodecCtx->codec_type = AVMEDIA_TYPE_AUDIO;

    if(m_iAacType == 0){
        m_pCodecCtx->profile=FF_PROFILE_AAC_LOW;
    }else{
        m_pCodecCtx->profile=FF_PROFILE_AAC_HE;
    }

//    char fmt[256];
//
//    for (int i = 0; m_pCodec->sample_fmts[i] != AV_SAMPLE_FMT_NONE ; ++i) {
//        LOGW("m_pCodec->sample_fmts[%d] = %d", i, m_pCodec->sample_fmts[i]);
//    }
//
//    LOGW("m_pCodecCtx->sample_fmt = %d", m_pCodecCtx->sample_fmt);
//
//    LOGW("m_pCodecCtx = %p", m_pCodecCtx);
//
//
//    for (int i = 0; m_pCodecCtx->codec->sample_fmts[i] != AV_SAMPLE_FMT_NONE ; ++i) {
//        LOGW("m_pCodecCtx->codec->sample_fmts[%d] = %d", i, m_pCodecCtx->codec->sample_fmts[i]);
//    }

    int iRet = 0;
    if((iRet = avcodec_open2(m_pCodecCtx, m_pCodec, NULL)) < 0) {
        char buf[1024];
        av_strerror(iRet, buf, 1024);
        LOGW("m_pCodecCtx = %p", m_pCodecCtx);
        LOGE("avcodec_open failed : %d(%s), m_pCodecCtx->sample_fmt = %d", iRet, buf, m_pCodecCtx->sample_fmt);
        LOGW("CAudioFrameEncoder::Init Fail, Could not open codec");
        return false;
    }

    m_pFrame = av_frame_alloc();
    if(!m_pFrame){
        LOGW("CAudioFrameEncoder::Init Fail, Malloc Frame Fail");
        return false;
    }

    m_pFrame->nb_samples = m_pCodecCtx->frame_size;
    m_pFrame->format = m_pCodecCtx->sample_fmt;
    m_pFrame->channels = m_pCodecCtx->channels;
    m_pFrame->channel_layout = m_pCodecCtx->channel_layout;

    m_nSamplesSize = av_samples_get_buffer_size(NULL, m_pCodecCtx->channels, m_pCodecCtx->frame_size, m_pCodecCtx->sample_fmt, 0);
    m_samples = (uint8_t*)av_malloc(m_nSamplesSize);
    if(avcodec_fill_audio_frame(m_pFrame, m_pCodecCtx->channels, m_pCodecCtx->sample_fmt, (const uint8_t*)m_samples, m_nSamplesSize, 0) < 0)
    {
        LOGW("CAudioFrameEncoder::Init Fail, Could not setup audio frame");
        return false;
    }

    m_pPcmBuffer = (uint8_t*) malloc(sizeof(uint8_t)* m_nSamplesSize);
    m_uPcmBufLen = 0;

    av_init_packet(&m_packet);
    av_new_packet(&m_packet, m_pCodecCtx->frame_size);

    m_bStopped = false;
    return true;
}

void audioEncodeHandle(void *context)
{
    CAudioFrameEncoder* encoder = (CAudioFrameEncoder*)context;
    if(NULL != encoder)
    {
        encoder->run();
    }
}

void CAudioFrameEncoder::start()
{
    m_bStopped = false;
    
    pthread_attr_t   attr;
    struct   sched_param   param;
    pthread_attr_init(&attr);
    pthread_attr_setschedpolicy(&attr, SCHED_RR);

    int max = sched_get_priority_max(SCHED_RR);
    int min = sched_get_priority_min(SCHED_RR);
    
    param.sched_priority  = (max + min)/2;
    pthread_attr_setschedparam(&attr, &param);

    int res = pthread_create(&m_ThreadId, &attr, (void* (*)(void*))&audioEncodeHandle, this);
    
    pthread_attr_destroy(&attr);
    
    
    if (0 != res) {
        mState = STOPED;
        LOGI("pthread_create error.");
    }else{
        mState = RUNNING;
    }
}


void CAudioFrameEncoder::stop()
{
    m_bStopped = true;
    if (mState != STOPED)
    {
        pthread_join(m_ThreadId, NULL);
        mState = STOPED;
    }
}

void CAudioFrameEncoder::release()
{
    if(m_pFrame){
        av_frame_free(&m_pFrame);
        m_pFrame = NULL;
    }

    if(m_samples){
        av_free(m_samples);
        m_samples = NULL;
    }

    if(NULL != m_pPcmBuffer){
        av_free(m_pPcmBuffer);
        m_pPcmBuffer = NULL;
    }

    avcodec_close(m_pCodecCtx);

    if(m_pCodecCtx){
        av_free(m_pCodecCtx);
        m_pCodecCtx = NULL;
    }
    LOGI("CAudioFrameEncoder::released");
}

uint32_t GetTickCount()
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    
    uint32_t mt = ((uint32_t)tv.tv_sec)*1000+(uint32_t)tv.tv_usec/1000;
    
    return mt;
}

void CAudioFrameEncoder::run()
{
    LOGI("CAudioFrameEncoder running");

    initCodec();

    int popLength;
    int64_t pts;
    int timeout = 100;
    uint8_t * encodeBuffer = (uint8_t*) malloc(RECORD_BUFFER_SIZE * sizeof(uint8_t));
    if (NULL == encodeBuffer){
        LOGE("malloc encoder buffer faield, CAudioFrameEncoder run exit");
        return ;
    }
    int i=0;
//    uint32_t t1, t2, t3, t4, t5, t6;
    while (!m_bStopped){
        //hp
//        t1 = GetTickCount();
        popLength = (*audioEncodertryPop)(m_delegate, encodeBuffer,RECORD_BUFFER_SIZE, timeout, &pts);
//        t2 = GetTickCount();
        //QueueManager::getInstance()->getAudioEncodeQueue()->trypop(encodeBuffer,
//                                                                               RECORD_BUFFER_SIZE, timeout, pts);
        if (popLength == 0){
            LOGI("trypop timeout");
            continue;
        }

        uint32_t needLength = m_nSamplesSize - m_uPcmBufLen;

        if (needLength == popLength){
            // 数据刚好够编码，开始编码
            memcpy(m_pPcmBuffer + m_uPcmBufLen, encodeBuffer, popLength);
            m_uPcmBufLen += popLength;
            
//            t3 = GetTickCount();
            EncodeAndPush(m_pPcmBuffer, m_uPcmBufLen, pts);
//            t4 = GetTickCount();
            
            memset(m_pPcmBuffer, m_nSamplesSize, 0);
            m_uPcmBufLen = 0;
        }
        else if (needLength > popLength){
            // 数据不够编码的长度，缓存pcm数据，不编码
            memcpy(m_pPcmBuffer + m_uPcmBufLen, encodeBuffer, popLength);
            m_uPcmBufLen += popLength;
        }
        else{
            // 数据多于编码的长度，凑够编码的数据然后缓存剩余的数据
            memcpy(m_pPcmBuffer + m_uPcmBufLen, encodeBuffer, needLength);
//            t5 = GetTickCount();
            EncodeAndPush(m_pPcmBuffer, m_uPcmBufLen, pts);
//            t6 = GetTickCount();
            m_uPcmBufLen = popLength - needLength;
            memcpy(m_pPcmBuffer, encodeBuffer + needLength, m_uPcmBufLen);
        }
        
//        printf("a1 = %u, a2 = %u, a3 = %u\n", t2 - t1, t4- t3, t6 - t5 );
    }
    

    mState = STOPED;
//  hp
//    QueueManager::getInstance()->getAudioEncodeQueue()->clear();
    (*audioEncoderClear)(m_delegate);
    free(encodeBuffer);
    release();
    LOGI("CAudioFrameEncoder run exit");
}

//����
bool CAudioFrameEncoder::EncodeAndPush(uint8_t* lpData, uint32_t liDataLen, unsigned int timestamp)
{
    bool  bret = false;
    int ret = 0;
    int got_output = 0;
//    uint32_t t11, t22;
    if(!m_pCodecCtx || !m_pFrame)
    {
        LOGW("CAudioFrameEncoder init failed");
        return false;
    }

    if(liDataLen != m_nSamplesSize){
        LOGI("CAudioFrameEncoder  liDataLength=%u, m_nSamplesSize=%u", liDataLen, m_nSamplesSize);
        return false;
    }

    memcpy(m_samples, lpData, liDataLen);

    //uint64_t startus = GetUSec();
//    t11 = GetTickCount();
    ret = avcodec_encode_audio2(m_pCodecCtx, &m_packet, m_pFrame, &got_output);
//    t22 = GetTickCount();
    
//    printf("t33 = %u\n", t22 - t11);
    if (ret < 0) {
        LOGW("CAudioFrameEncoder::Encode Error, encoding audio frame: %d", ret);
        return false;
    }

    if(got_output > 0)
    {

//
//        if(lbAdts == true)
//        {
//            //����������ݰ���ADTSͷ
//            if(liEncodeDataLen >= m_packet.size)
//            {
//                liEncodeDataLen = m_packet.size;
//                memcpy(lpEncodeData, m_packet.data, liEncodeDataLen);
//                bret = true;
//            }
//            else
//            {
//                bret = false;
//            }
//        }
//        else
//        {
//            //�����������ȥ��ADTSͷ
//            if(m_packet.size > 7)
//            {
//                if(liEncodeDataLen >= m_packet.size - 7)
//                {
//                    liEncodeDataLen = m_packet.size - 7;
//                    memcpy(lpEncodeData, m_packet.data+7, liEncodeDataLen);
//                    bret = true;
//                }
//                else
//                {
//                   bret = false;
//                }
//            }
//            else
//            {
//                liEncodeDataLen = 0;
//                bret = true;
//            }
//        }

        if(m_packet.size > 7)
        {
            LOGI("CAudioFrameEncoder audio get %d bytes, timestamp = %u! ", m_packet.size, timestamp);
            //hp
//            DataPusher::getInstance()->pushAACData(m_packet.data, m_packet.size, timestamp);
            (*audioEncoderPushAACData)(m_delegate,m_packet.data, m_packet.size, timestamp);
        }
        else{
            LOGW("Encode audio get size = %d! ", m_packet.size);
        }

//        saveAacFile();
        av_free_packet(&m_packet);
    }
    else
    {
        LOGW("CAudioFrameEncoder::Encode Error, Not got_output");
    }

    return bret;
}


void CAudioFrameEncoder::saveAacFile()
{
    static  int index = 0;
//
//    if (index > 5){
//        return;
//    }

    char filename[128];
    sprintf(filename, "/sdcard/mj/softAudio.aac", index++);

    FILE* file = fopen(filename, "ab+");
    fwrite(m_packet.data, 1, m_packet.size, file);
    fclose(file);
}

void CAudioFrameEncoder::savePcmFile(uint8_t* data, uint32_t length)
{
    char filename[128];
    sprintf(filename, "/sdcard/mj/softAudio.pcm");

    FILE* file = fopen(filename, "ab+");
    fwrite(data, 1, length, file);
    fclose(file);
}






