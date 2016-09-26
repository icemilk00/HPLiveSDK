//
// Created by mj on 16-2-19.
//

#ifndef MVBOX_NEW_QUEUE_H
#define MVBOX_NEW_QUEUE_H

#include <sys/types.h>
#include <pthread.h>

#include <stdio.h>

typedef void (*LogCallBackHandler)(void *delegate, char *logStr);
typedef void (*CallBackHandler)(void *delegate);

typedef struct PacketList{
    void* data;     		// 数据
    int32_t length;     	// 数据长度
    int64_t pts;            // 播放时长，用来音视频同步
    struct PacketList* next;
}StruPacketList;

class Queue {
public:
    Queue();
    ~Queue();

    int32_t push(void* data, int32_t length, int64_t pos);
    int32_t pop(void* data, int32_t length, int64_t *pts);
    int32_t trypop(void* data, int32_t length, long timeOutwithms, int64_t *pts);

    void finish();
    void start();

    void clear();

    int32_t getQueueSize();

private:
    StruPacketList *m_pFirstPkt;    // offscreen pkt位置
    StruPacketList *m_pLastPkt;         // 最后一个pkt位置

    int32_t m_nPackets;                 // 队列里packet的个数

    bool m_bFinished;

    pthread_mutex_t m_mutex;
    pthread_cond_t m_cond;
    

public:
    // 要实现回调的对象
    void *m_delegate;

    //回调函数声明
    LogCallBackHandler audioLogCallBack;
    CallBackHandler audioDropPacketCallBack;
};


#endif //MVBOX_NEW_QUEUE_H
