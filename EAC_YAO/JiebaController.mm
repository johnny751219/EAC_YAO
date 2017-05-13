//
//  JiebaController.m
//  EAC_YAO
//
//  Created by Johnny_Yao on 2017/5/9.
//  Copyright © 2017年 Johnny_Yao. All rights reserved.
//

#import "JiebaController.h"
#include "Segmentor.h"

@implementation JiebaController
 
- (NSString *) readyToSeg:(NSString*)inputstring{
    const char* sentence = [inputstring UTF8String];
    std::vector<std::string> words;
    JiebaCut(sentence, words);
    std::string result;
    result << words;
    inputstring=[NSString stringWithUTF8String:result.c_str()];
    //NSLog(@"1%@", inputstring);
    return inputstring;
    }

- (void) JiebaInitial {
    NSString *dictPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"iosjieba.bundle/dict/jieba.dict.big.utf8"];
    NSString *hmmPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"iosjieba.bundle/dict/hmm_model.utf8"];
    NSString *userDictPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"iosjieba.bundle/dict/user.dict.utf8"];
    const char *cDictPath = [dictPath UTF8String];
    const char *cHmmPath = [hmmPath UTF8String];
    const char *cUserDictPath = [userDictPath UTF8String];
    JiebaInit(cDictPath, cHmmPath, cUserDictPath);
    std::vector<std::string> words;
    //NSLog(@"%@",dictPath);
    //NSLog(@"%@",hmmPath);
    //NSLog(@"%@",userDictPath);
}
    
    
@end
