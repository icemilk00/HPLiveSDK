//
// Created by mj on 16-2-19.
//

#include <errno.h>
#include <string.h>
#include <sys/time.h>
#include "Queue.h"

#include <time.h>

#include <unistd.h>
#define LOGE(...)
#define Q_MAX_LEN 10
#define TIME_OVER_FLOW  (1000 * 1000 * 1000)
//
//#include "logUtil.h"

Queue::Queue()
{
	m_bFinished = false;
    m_nPackets = 0;
    m_pFirstPkt = NULL;
    m_pLastPkt = NULL;

    pthread_mutex_init(&m_mutex, NULL);
    m_cond = PTHREAD_COND_INITIALIZER;
    pthread_cond_init(&m_cond, NULL);
}


Queue::~Queue()
{
    clear();
    pthread_mutex_destroy(&m_mutex);
    pthread_cond_destroy(&m_cond);
}

int32_t Queue::push(void* data, int32_t length, int64_t pos)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    long beginTime = tv.tv_sec * 1000 + tv.tv_usec/1000;

    if(!data || length <= 0 || Q_MAX_LEN <= m_nPackets){
        LOGE("queue push: parameter error!");
        char *logStr = "drop packet!!!!\n";
        (*audioLogCallBack)(m_delegate, logStr);
        (*audioDropPacketCallBack)(m_delegate);
        return -1;
    }

    StruPacketList* pkt = new StruPacketList();
    if(!pkt){
        LOGE("queue push: malloc PacketList failed!");
        return -1;
    }
    
    pkt->length = length;
    pkt->data = new u_int8_t[pkt->length];
    pkt->pts = pos;
    memcpy(pkt->data, data, pkt->length);
    pkt->next = NULL;

    pthread_mutex_lock(&m_mutex);

    // 第一个入队列的
    if(NULL == m_pFirstPkt && NULL == m_pLastPkt){
        m_pFirstPkt = pkt;
        m_pLastPkt = pkt;
    }
    else
    {
        m_pLastPkt->next = pkt;
        m_pLastPkt = pkt;
    }

    ++m_nPackets;
    pthread_cond_signal(&m_cond);

    pthread_mutex_unlock(&m_mutex);
    
    struct timeval tv_end;
    gettimeofday(&tv_end, NULL);
    long endTime = tv_end.tv_sec * 1000 + tv_end.tv_usec/1000;
    if (endTime - beginTime > 1) {
        char str_end[100];
        sprintf(str_end,"%ld -- push time :【%ld】\n",endTime, endTime - beginTime);
        (*audioLogCallBack)(m_delegate, str_end);
    }
    

    return 0;
}


int32_t Queue::pop(void* data, int32_t length, int64_t *pts)
{
    int ret = 0;

    if(!data){
        return -1;
    }

    pthread_mutex_lock(&m_mutex);

    StruPacketList* popPkt = m_pFirstPkt;

    while (!popPkt) { //is empty
        if (m_bFinished){
//            LOGI("queue pop: finished");
            pthread_mutex_unlock(&m_mutex);
            return -1;
        }

        pthread_cond_wait(&m_cond, &m_mutex);
        popPkt = m_pFirstPkt;
    }

    if(length < popPkt->length){
        LOGE("queue pop : length not enough!");
        pthread_mutex_unlock(&m_mutex);
        return -1;
    }

    if(!popPkt->data){
        LOGE("queue pop : packet data is NULL!");
        pthread_mutex_unlock(&m_mutex);
        return -1;
    }

    memcpy(data, popPkt->data, popPkt->length);
    ret = popPkt->length;
    *pts = popPkt->pts;

    m_pFirstPkt = m_pFirstPkt->next;
    if(m_pLastPkt == popPkt){
    	m_pLastPkt = NULL;
    }

    delete[] popPkt->data;
    delete popPkt;
    --m_nPackets;

    pthread_mutex_unlock(&m_mutex);

    return ret;
}

int32_t Queue::trypop(void* data, int32_t length, long timeOutwithms, int64_t *pts)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    long beginTime = tv.tv_sec * 1000 + tv.tv_usec/1000;
    
    int ret = 0;

    if(!data){
        return -1;
    }
    pthread_mutex_lock(&m_mutex);

    struct timeval now;
    struct timespec outtime;
    StruPacketList* popPkt = m_pFirstPkt;

    while (!popPkt) { //is empty'
        if (m_bFinished){
//            LOGI("queue trypop : finished");
            pthread_mutex_unlock(&m_mutex);
            return -1;
        }

        gettimeofday(&now, NULL);
        outtime.tv_sec = now.tv_sec + timeOutwithms / 1000;
        outtime.tv_nsec = now.tv_usec * 1000 + (timeOutwithms % 1000) * 1000 * 1000;
        if(outtime.tv_nsec >= TIME_OVER_FLOW){
            (outtime.tv_sec)++;
            outtime.tv_nsec -= TIME_OVER_FLOW;
        }
        int waitresult = pthread_cond_timedwait(&m_cond, &m_mutex, &outtime);
        if(waitresult == ETIMEDOUT){
            printf("time_wait timeout!!!\n");
            pthread_mutex_unlock(&m_mutex);
            return ret;
        }else if(waitresult != 0){
             printf("time_wait waitresutl = %d\n", waitresult);
        }
        
//        if (pthread_cond_timedwait(&m_cond, &m_mutex, &outtime) == ETIMEDOUT) {
//            pthread_mutex_unlock(&m_mutex);
////            LOGI("queue trypop : time out!");
//            printf("timeout");
//            return ret;
//        }

        popPkt = m_pFirstPkt;
    }

    if(length < popPkt->length){
        LOGE("queue trypop : length not enough! poplength = %d, length = %d", popPkt->length, length);
        pthread_mutex_unlock(&m_mutex);
        return -1;
    }

    if(!popPkt->data){
        LOGE("queue trypop : packet data is NULL!");
        pthread_mutex_unlock(&m_mutex);
        return -1;
    }

    memcpy(data, popPkt->data, popPkt->length);
    ret = popPkt->length;
    *pts = popPkt->pts;

    m_pFirstPkt = m_pFirstPkt->next;
    if(m_pLastPkt == popPkt){
        m_pLastPkt = NULL;
    }

    delete[] popPkt->data;
    delete popPkt;
    --m_nPackets;

    pthread_mutex_unlock(&m_mutex);
    
    
    struct timeval tv_end;
    gettimeofday(&tv_end, NULL);
    long endTime = tv_end.tv_sec * 1000 + tv_end.tv_usec/1000;
    if (endTime - beginTime > 1) {
        char str_end[100];
        sprintf(str_end,"%ld -- pop time :【%ld】\n",endTime, endTime - beginTime);
        (*audioLogCallBack)(m_delegate, str_end);
    }

    return ret;
}

void Queue::clear() {
    pthread_mutex_lock(&m_mutex);

    StruPacketList* pkt = m_pFirstPkt;

    while (NULL != pkt)
    {
        StruPacketList* deletePkt = pkt;
        pkt = pkt->next;
        if(deletePkt->data){
            delete[] deletePkt->data;
            deletePkt->data = NULL;
        }
        delete deletePkt;
        deletePkt = NULL;
    }

    m_pFirstPkt = NULL;
    m_pLastPkt = NULL;

    m_nPackets = 0;
    m_bFinished = false;

    pthread_cond_signal(&m_cond);

    pthread_mutex_unlock(&m_mutex);
}


void Queue::finish() {
    pthread_mutex_lock(&m_mutex);
    m_bFinished = true;
    pthread_mutex_unlock(&m_mutex);
}


void Queue::start() {
    pthread_mutex_lock(&m_mutex);
    m_bFinished = false;
    pthread_mutex_unlock(&m_mutex);
}

int32_t Queue::getQueueSize(){
    int32_t ret = 0;
    pthread_mutex_lock(&m_mutex);
    ret = m_nPackets;
    pthread_mutex_unlock(&m_mutex);
    return ret;
}
