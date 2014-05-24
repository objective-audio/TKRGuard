//
//  TKRGuardToken.m
//
//  Created by ToKoRo on 2013-12-13.
//

#import "TKRGuardToken.h"

static const NSTimeInterval TKRGuardTokenLoopInterval = 0.05;

@interface TKRGuardToken ()
@end 

@implementation TKRGuardToken {
    NSUInteger _waitCount;
    TKRGuardStatus _resultStatus;
    BOOL _preceding;
    NSUInteger _precedingCount;
}

//----------------------------------------------------------------------------//
#pragma mark - Lifecycle
//----------------------------------------------------------------------------//

- (instancetype)init
{
    if ((self = [super init])) {
        _waitCount = 0;
        _resultStatus = TKRGuardStatusNil;
        _preceding = NO;
        _precedingCount = 0;
    }
    return self;
}

//----------------------------------------------------------------------------//
#pragma mark - Public Interface
//----------------------------------------------------------------------------//
    
- (TKRGuardStatus)waitWithTimeout:(NSTimeInterval)timeout
{
    TKRGuardStatus resultStatus = TKRGuardStatusNil;
    NSDate *expiryDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (YES) {
        @synchronized(self) {
            if (!self.isWaiting) {
                resultStatus = _resultStatus;
                break;
            }
        }
        if (NSOrderedDescending == [[NSDate date] compare:expiryDate]) {
            return TKRGuardStatusTimeouted;
        }
        NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:TKRGuardTokenLoopInterval];
        [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
    }
    return resultStatus;
}

- (void)resumeWithStatus:(TKRGuardStatus)status
{
    @synchronized(self) {
        self.resultStatus = status;
        if (_preceding) {
            ++_precedingCount;
        } else {
            --_waitCount;
        }
    }
}

- (BOOL)isWaiting
{
    BOOL isWaiting = NO;
    @synchronized(self) {
        if (_preceding || TKRGuardStatusNil == _resultStatus || 0 < _waitCount) {
            isWaiting = YES;
        }
    }
    return isWaiting;
}

- (void)setWaitCount:(NSUInteger)count
{
    @synchronized(self) {
        _waitCount = count - _precedingCount;
        _precedingCount = 0;
    }
}

- (NSUInteger)waitCount
{
    NSUInteger count = 0;
    @synchronized(self) {
        count = _waitCount;
    }
    return count;
}

- (void)setResultStatus:(TKRGuardStatus)status
{
    @synchronized(self) {
        if (_resultStatus != TKRGuardStatusFailure) {
            _resultStatus = status;
        }
    }
}

- (TKRGuardStatus)resultStatus
{
    TKRGuardStatus status = TKRGuardStatusNil;
    @synchronized(self) {
        status = _resultStatus;
    }
    return status;
}

- (void)setPreceding:(BOOL)preceding
{
    @synchronized(self) {
        _preceding = preceding;
    }
}

- (BOOL)isPreceding
{
    BOOL isPreceding = NO;
    @synchronized(self) {
        isPreceding = _preceding;
    }
    return isPreceding;
}

@end
