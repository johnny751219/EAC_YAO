//
//  JiebaController.h
//  
//
//  Created by Johnny_Yao on 2017/5/9.
//
//

#import <Foundation/Foundation.h>

@interface JiebaController : NSObject
    
    @property (strong, nonatomic) id someProperty;
   
- (NSString *) readyToSeg:(NSString*)inputstring;
- (void) JiebaInitial;

@end

