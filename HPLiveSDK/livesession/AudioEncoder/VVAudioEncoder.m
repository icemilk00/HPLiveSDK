//
//  VVAudioEncoder.m
//  LiveDemo
//
//  Created by hp on 16/6/17.
//  Copyright © 2016年 hxp. All rights reserved.
//

#import "VVAudioEncoder.h"
#import "VVLivePacketer.h"

@interface VVAudioEncoder()
{
    AudioConverterRef _audioCoverter;   //编码器

    size_t *_pcmBuffer;
    UInt32 _pcmBufferSize;
    
    UInt8 *_aacBuffer;
    UInt32 _aacBufferSize;
    
    NSMutableData *_saveFlvData;
    FILE *fp;
    
    BOOL _isSetupFlvHead;
    
    
}

@end

@implementation VVAudioEncoder

-(id)init
{
    self = [self initWithConfig:[VVLiveAudioConfiguration defaultConfiguration]];
    if (self) {

        
    }
    return self;
}

-(id)initWithConfig:(VVLiveAudioConfiguration *)config
{
    self = [super init];
    if (self) {
        
        _pcmBufferSize = 0;
        _pcmBuffer = NULL;
        
        _currentAudioEncodeConfig = config;
        

#ifdef DEBUG
        _isSetupFlvHead = NO;
        _isNeedSaveFlvFile = NO;
        _saveFlvData = [[NSMutableData alloc] init];
        if(_isNeedSaveFlvFile) [self initForFilePath];
#endif
        
    }
    return self;
}


- (void)initForFilePath
{

    char *path = [VVLivePacketer GetFilePathByfileName:"IOSTestAudio.flv"];
    NSLog(@"%s",path);
    self->fp = fopen(path,"wb");
}

/*
 *  根据采集的源数据来定义编码器的参数
 */
-(void)makeAudioConverterFromInPutSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    //获取源流的参数描述
    AudioStreamBasicDescription inputAudioStreamDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    
    [self makeAudioConverterFromInPutDescription:inputAudioStreamDescription];
}

/*
 *  根据默认参数来定义编码器的参数
 */
-(void)makeAudioConverterFromDefaultInPutDescription
{
    AudioStreamBasicDescription defaultinputAudioStreamDescription = {0};
    defaultinputAudioStreamDescription.mSampleRate = _currentAudioEncodeConfig.audioSampleRate;
    defaultinputAudioStreamDescription.mFormatID = kAudioFormatLinearPCM;
    defaultinputAudioStreamDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    defaultinputAudioStreamDescription.mChannelsPerFrame = (UInt32)_currentAudioEncodeConfig.numberOfChannels;
    defaultinputAudioStreamDescription.mFramesPerPacket = 1;
    defaultinputAudioStreamDescription.mBitsPerChannel = 16;
    defaultinputAudioStreamDescription.mBytesPerFrame = defaultinputAudioStreamDescription.mBitsPerChannel / 8 * defaultinputAudioStreamDescription.mChannelsPerFrame;
    defaultinputAudioStreamDescription.mBytesPerPacket = defaultinputAudioStreamDescription.mBytesPerFrame * defaultinputAudioStreamDescription.mFramesPerPacket;
    [self makeAudioConverterFromInPutDescription:defaultinputAudioStreamDescription];
}


-(void)makeAudioConverterFromInPutDescription:(AudioStreamBasicDescription)inputAudioStreamDescription
{
    
    AudioStreamBasicDescription outputAudioStreamDescription = {0};
    
    //采样率：保持和源数据的一致
    outputAudioStreamDescription.mSampleRate = inputAudioStreamDescription.mSampleRate;
    
    //目前应该不支持HE，经测试，touch可以编码成功，但都没声音，iphone6直接编码器报错
    //https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/MultimediaPG/UsingAudio/UsingAudio.html#//apple_ref/doc/uid/TP40009767-CH2-SW6
    //编码为AAC格式
    outputAudioStreamDescription.mFormatID = _currentAudioEncodeConfig.audioFormatID;//kAudioFormatMPEG4AAC_HE;//
//    outputAudioStreamDescription.mFormatFlags = kMPEG4Object_AAC_LC;
//    每个包中含有的数据量,由于是可变不固定的，设置为0
    outputAudioStreamDescription.mBytesPerPacket = 0;
    //每个包中含有的音频数据帧量，这里是固定的
    outputAudioStreamDescription.mFramesPerPacket = _currentAudioEncodeConfig.mFramesPerPacket;//2048;//
    //每个数据帧中的字节，
    outputAudioStreamDescription.mBytesPerFrame = 0;
    // 1:单声道；2:立体声,不能为0
    outputAudioStreamDescription.mChannelsPerFrame = (UInt32)_currentAudioEncodeConfig.numberOfChannels;
    // 每个数据帧中每个通道样本的位数
    outputAudioStreamDescription.mBitsPerChannel = 0;
    outputAudioStreamDescription.mReserved = 0;
    //kAudioFormatMPEG4AAC
    AudioClassDescription *inClassDescriptions = [self getAudioClassDescriptionWithType:_currentAudioEncodeConfig.audioFormatID fromManufacturer:kAppleSoftwareAudioCodecManufacturer];

    //这里也可以使用AudioConverterNew进行创建，AudioConverterNew会使用默认编码方式，有硬编硬编没硬编软编码，AudioConverterNewSpecific可以直接指定编码方式，这里用硬编
    OSStatus status = AudioConverterNewSpecific(&inputAudioStreamDescription, &outputAudioStreamDescription, 2, inClassDescriptions, &_audioCoverter);
    if (status != 0) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                             code:status
                                         userInfo:nil];
        NSLog(@"Error: %@", [error description]);
        return;
    }
    
//    UInt32 ulBitRate = _currentAudioEncodeConfig.audioBitrate;
//    UInt32 ulSize = sizeof(ulBitRate);
//    status = AudioConverterSetProperty(_audioCoverter, kAudioConverterEncodeBitRate, ulSize, &ulBitRate);
    
//    默认编码码率128K，AAC-LC设置24K 和 32K 编码器直接报错，64K会有噪音
//    UInt32 ulSize = sizeof(UInt32);
//    UInt32 ulBitRate;
//    AudioConverterGetProperty(_audioCoverter, kAudioConverterEncodeBitRate, &ulSize, &ulBitRate);
//    NSLog(@"ulbitrate = %d", ulBitRate);
}

-(AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer
{
    static AudioClassDescription inClassDescription;
    
    UInt32 encoderSpecifier = type;
    OSStatus status;
    
    UInt32 size;
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (status) {
        NSLog(@"error getting audio format propery info: %d", (int)(status));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (status) {
        NSLog(@"error getting audio format propery: %d", (int)(status));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&inClassDescription, &(descriptions[i]), sizeof(inClassDescription));
            return &inClassDescription;
        }
    }
    
    return nil;
}

//通过bufflist编码
-(void)encodeBufferList:(AudioBufferList)bufferList timeStamp:(uint64_t)timeStamp
{

    if (!_audioCoverter) {
        [self makeAudioConverterFromDefaultInPutDescription];
    }
    
    if(!_aacBuffer){
        _aacBuffer = malloc(bufferList.mBuffers[0].mDataByteSize);
    }
    
    NSError *error = nil;
    
    AudioBufferList outputAudioBufferList = {0};
    outputAudioBufferList.mNumberBuffers              = 1;
    outputAudioBufferList.mBuffers[0].mNumberChannels = bufferList.mBuffers[0].mNumberChannels;
    outputAudioBufferList.mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    outputAudioBufferList.mBuffers[0].mData = _aacBuffer;
    
    UInt32 ioOutputDataPacketSize = 1;
    
    OSStatus status = AudioConverterFillComplexBuffer(_audioCoverter, inInputDataProc, &bufferList, &ioOutputDataPacketSize, &outputAudioBufferList, NULL);
    NSData *data = nil;
    VVAudioEncodeFrame *audioFrame = [[VVAudioEncodeFrame alloc] init];
    if (status == 0) {
        NSData *rawAAC = [NSData dataWithBytes:outputAudioBufferList.mBuffers[0].mData length:outputAudioBufferList.mBuffers[0].mDataByteSize];
        NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
        NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
        [fullData appendData:rawAAC];
        data = fullData;
        
        audioFrame.encodeData = data;
        audioFrame.timeStamp = timeStamp;
        char exeData[2];
        exeData[0] = _currentAudioEncodeConfig.asc[0];// 0x12;
        exeData[1] = _currentAudioEncodeConfig.asc[1];// 0x10;
        audioFrame.audioInfo = [NSData dataWithBytes:exeData length:2];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioEncodeComplete:)]) {
            [self.delegate audioEncodeComplete:audioFrame];
        }
        
        if (_isNeedSaveFlvFile ) {

            if (_isSetupFlvHead == NO) {
                _isSetupFlvHead = YES;
                
                NSData *audioData = [VVLivePacketer flvAudioHeadsWithAudioInfo:audioFrame.audioInfo];
                fwrite(audioData.bytes, 1,audioData.length,fp);
            }
            
            VVAudioEncodeFrame *saveAudioFrame = [[VVAudioEncodeFrame alloc] init];
            saveAudioFrame.encodeData = audioFrame.encodeData;
            saveAudioFrame.timeStamp = [self.delegate sessionTimeStampForLocal];
            saveAudioFrame.audioInfo = audioFrame.audioInfo;
            NSData *audioData = [VVLivePacketer audioDataWithNALUFrame:saveAudioFrame];
            fwrite(audioData.bytes, 1,audioData.length,fp);
        }
        
    } else {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"audio encode failed : %@", error.description);
    }
}

static OSStatus inInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    AudioBufferList bufferList = *(AudioBufferList*)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData           = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize   = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}

//通过sampleBuffer编码
-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp
{
    CFRetain(sampleBuffer);
    
    if (!_audioCoverter) {
        [self makeAudioConverterFromInPutSampleBuffer:sampleBuffer];
    }
    
    if(!_aacBuffer){
        _aacBufferSize = 1024;
        _aacBuffer = malloc(_aacBufferSize * sizeof(uint8_t));
    }
    /*
     CMBlockBuffer是在处理系统中用于移动内存块的对象。它表示在可能的非连续内存区域中，数据的连续值。怎么理解？我的理解是，可能CMBlockBuffer中的数据存
     放在不同的区域中，可能来自内存块，也可能来自其他的buffer reference，使用CMBlockBuffer就隐藏了具体的存储细节，让你可以简单地使用0到
     CMBlockBufferGetDataLength的索引来定位数据。
    */
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    CFRetain(blockBuffer);
    
    //获取_pcmBuffer大小和初始指针
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
    NSError *error = nil;
    if (status != kCMBlockBufferNoErr) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
    
    memset(_aacBuffer, 0, _aacBufferSize);
    
    AudioBufferList outputAudioBufferList = {0};
    outputAudioBufferList.mNumberBuffers = 1;
    outputAudioBufferList.mBuffers[0].mDataByteSize = _aacBufferSize;
    outputAudioBufferList.mBuffers[0].mData = _aacBuffer;
    
    AudioStreamPacketDescription outputPacketDescription = {0};
    UInt32 ioOutputDataPacketSize = 1;
    
    status = AudioConverterFillComplexBuffer(_audioCoverter, incodeSampleBufferDataProc, (__bridge void * _Nullable)(self), &ioOutputDataPacketSize, &outputAudioBufferList, &outputPacketDescription);
    NSData *data = nil;
    VVAudioEncodeFrame *audioFrame = [[VVAudioEncodeFrame alloc] init];
    if (status == 0) {
        NSData *rawAAC = [NSData dataWithBytes:outputAudioBufferList.mBuffers[0].mData length:outputAudioBufferList.mBuffers[0].mDataByteSize];
        NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
        NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
        [fullData appendData:rawAAC];
        data = fullData;
        
        audioFrame.encodeData = data;
        audioFrame.timeStamp = timeStamp;
        char exeData[2];
        exeData[0] = 0x12;
        exeData[1] = 0x10;
        audioFrame.audioInfo = [NSData dataWithBytes:exeData length:2];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioEncodeComplete:)]) {
            [self.delegate audioEncodeComplete:audioFrame];
        }
        
    } else {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"audio encode failed : %@", error.description);
    }
    
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
    
}

static OSStatus incodeSampleBufferDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    VVAudioEncoder *encoder = (__bridge VVAudioEncoder *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackets;
    //NSLog(@"Number of packets requested: %d", (unsigned int)requestedPackets);
    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    if (copiedSamples < requestedPackets) {
        //NSLog(@"PCM buffer isn't full enough!");
        *ioNumberDataPackets = 0;
        return -1;
    }
    *ioNumberDataPackets = 1;
    //NSLog(@"Copied %zu samples into ioData", copiedSamples);
    return noErr;
}

- (size_t) copyPCMSamplesIntoBuffer:(AudioBufferList*)ioData {
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = _pcmBufferSize;
    _pcmBuffer = NULL;
    _pcmBufferSize = 0;
    return originalBufferSize;
}
/**
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData*) adtsDataForPacketLength:(NSUInteger)packetLength {
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = 4;  //44.1KHz
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

-(void)dealloc
{
    AudioConverterDispose(_audioCoverter);
    free(_aacBuffer);
}

@end
