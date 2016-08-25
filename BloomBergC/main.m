//
//  main.m
//  BloomBergC
//
//  Created by Adam Lovastyik on 2016. 06. 30..
//  Copyright © 2016. Bloomberg. All rights reserved.
//

//#import <Foundation/Foundation.h>
//
//int main(int argc, const char * argv[]) {
//    @autoreleasepool {
//        // insert code here...
//        NSLog(@"Hello, World!");
//    }
//    return 0;
//}

#import <objc/objc.h>
#import <objc/Object.h>
#import <Foundation/Foundation.h>

//static NSString * readLine() {
//    char buffer[512];
//    
//    if (fgets(buffer, sizeof(buffer), stdin) != NULL) {
//        return [[NSString stringWithUTF8String:buffer] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    }
//    
//    return nil;
//}

static NSString * readLine(NSString * contents, NSInteger *lineNumber) {
    
    NSArray *lines = [contents componentsSeparatedByString:@"\n"];
    if (*lineNumber < lines.count) {
        NSString *line = lines[*lineNumber];
        *lineNumber += 1;
        return line;
    }
    
    return nil;
}

static void printLine(NSString * line) {
    if (line) {
        //printf("%s\n", [line UTF8String]);
        NSLog(@"%s\n", [line UTF8String]);
    } else {
        //printf("(null)\n");
        NSLog(@"(null)\n");
    }
}

NSString* openFile(NSString * fileName) {
    
    return [NSString stringWithContentsOfFile:fileName];
    
}

#pragma mark - Objects

@interface Order : NSObject

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *orderNumber;
@property (nonatomic, retain) NSNumber *haddocks;
@property (nonatomic, retain) NSNumber *cods;
@property (nonatomic, retain) NSNumber *chips;

- (id)initWithString:(NSString*)orderString;

@end

@implementation Order

- (id)initWithString:(NSString*)orderString {
    
    self = [super init];
    if (self) {
     
        NSArray *comps = [orderString componentsSeparatedByString:@","];
        
        for (NSString *component in comps) {
            
            NSString *strippedComp = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([strippedComp rangeOfString:@"Order #"].location != NSNotFound) {
                //Order number
                self.orderNumber = strippedComp;
            }
            else if ([strippedComp rangeOfString:@"Haddock"].location != NSNotFound) {
                //Haddocks
                self.haddocks = [self extractNumberFrom:strippedComp];
            }
            else if ([strippedComp rangeOfString:@"Cod"].location != NSNotFound) {
                //Cods
                self.cods = [self extractNumberFrom:strippedComp];
            }
            else if ([strippedComp rangeOfString:@"Chip"].location != NSNotFound) {
                //Haddocks
                self.chips = [self extractNumberFrom:strippedComp];
            }
            else {
                //Date
                self.date = [self extractDateFrom:strippedComp];
            }
        }
    }
    
    return self;
}

- (NSNumber*)extractNumberFrom:(NSString*)text {
    
    @autoreleasepool {
        NSRange range = [text rangeOfString:@" "];
        if (range.location != NSNotFound) {
            NSString *value = [text substringToIndex:range.location];
            return [NSNumber numberWithInt:[value intValue]];
        }
    }
    
    return nil;
}

- (NSDate*)extractDateFrom:(NSString*)text {
    
    @autoreleasepool {
        
        NSDate *currentDate = [NSDate date];
        NSCalendar *currentCalendar = [NSCalendar currentCalendar];
        NSDateComponents *dateComps = [currentCalendar components:(NSCalendarUnitYear |
                                                                   NSCalendarUnitMonth |
                                                                   NSCalendarUnitDay |
                                                                   NSCalendarUnitTimeZone |
                                                                   NSCalendarUnitHour |
                                                                   NSCalendarUnitMinute |
                                                                   NSCalendarUnitSecond)
                                                         fromDate:currentDate];
        NSArray *components = [text componentsSeparatedByString:@":"];
        if (components.count == 3) {
            dateComps.hour = [components[0] integerValue];
            dateComps.minute = [components[1] integerValue];
            dateComps.second = [components[2] integerValue];
            
            return [currentCalendar dateFromComponents:dateComps];
        }
    }
    
    return nil;
}

@end

#pragma mark -

@interface TimeLineEvent : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *event;

- (id)initWithEvent:(NSString*)event date:(NSDate*)date;

@end

@implementation TimeLineEvent

- (id)initWithEvent:(NSString*)event date:(NSDate*)date {
    
    self = [super init];
    if (self) {
        self.date = date;
        self.event = event;
    }
    
    return self;
}

- (NSString*)formattedDateOf:(NSDate*)date {
    
    
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    
    NSDateComponents *dateComps = [currentCalendar components:(NSCalendarUnitTimeZone |
                                                               NSCalendarUnitHour |
                                                               NSCalendarUnitMinute |
                                                               NSCalendarUnitSecond)
                                                     fromDate:date];
    
    return [NSString stringWithFormat:@"%02li:%02li:%02li", (long)dateComps.hour, (long)dateComps.minute, (long)dateComps.second];
}

- (NSString*)description {
    
    return [NSString stringWithFormat:@"at %@, %@", [self formattedDateOf:self.date], self.event];
}

@end

#pragma mark -

@interface OrderProcessor : NSObject

@property (nonatomic, strong) Order *order;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, strong, readonly) NSArray *timeLine;

- (void)processOrder;

@end

#pragma mark  -

@implementation OrderProcessor

- (void)setOrder:(Order *)order {
    
    _order = order;
    
    if (!self.date || [self.date compare:order.date] == NSOrderedAscending) {
        _date = self.order.date;
    }
    
    _timeLine = [NSArray new];
}

- (void)addTimeLineEvent:(NSString*)event date:(NSDate*)date {
    
    NSMutableArray *temp = [NSMutableArray arrayWithArray:self.timeLine];
    
    [temp addObject:[[TimeLineEvent alloc] initWithEvent:event date:date]];
    
    _timeLine = [NSArray arrayWithArray:temp];
}

- (void)addTimeLineEvents:(NSArray*)events {
    
    NSMutableArray *temp = [NSMutableArray arrayWithArray:self.timeLine];
    
    [temp addObjectsFromArray:events];
    
    _timeLine = [NSArray arrayWithArray:temp];
}

- (void)sortTimeLine {
    
    NSArray *sortedEvents = [self.timeLine sortedArrayUsingComparator:^NSComparisonResult(TimeLineEvent* _Nonnull event1, TimeLineEvent* _Nonnull event2) {
        return [event1.date compare:event2.date];
    }];
    
    _timeLine = sortedEvents;
}

- (void)processOrder {
    
}

@end

#pragma mark -

@interface Fryer : OrderProcessor

@property (nonatomic, assign) NSTimeInterval delay;

- (NSTimeInterval)calculateFryTime;

@end

@implementation Fryer

- (NSTimeInterval)calculateFryTime {
    
    return 0;
}

@end

#pragma mark -

@interface ChipsFryer: Fryer

@property (nonatomic, assign, readonly) NSTimeInterval chipsFryTime;
@property (nonatomic, assign, readonly) NSInteger chipsFrierLimit;

@end

@implementation ChipsFryer

- (id)init {
    
    self = [super init];
    if (self) {
        _chipsFryTime = 120;
        _chipsFrierLimit = 4;
    }
    
    return self;
}

- (void)processOrder {

    self.date = [self.date dateByAddingTimeInterval:self.delay];

    NSInteger fryRounds = (NSInteger)ceil(self.order.chips.doubleValue / (double)self.chipsFrierLimit);
    
    NSInteger chips = self.order.chips.integerValue;

    for (int i = 0; i < fryRounds; i++) {

        NSInteger portion = chips > self.chipsFrierLimit ? self.chipsFrierLimit : chips;

        NSString *event = [NSString stringWithFormat:@"Begin Cooking %li Chips", (long)portion];
        [self addTimeLineEvent:event date:self.date];
        
        self.date = [self.date dateByAddingTimeInterval:self.chipsFryTime];

        chips -= portion;
    }
}

- (NSTimeInterval)calculateFryTime {
    
    NSInteger fryRounds = (NSInteger)ceil(self.order.chips.doubleValue / (double)self.chipsFrierLimit);
    NSTimeInterval fryTime = fryRounds * self.chipsFryTime;
    
    return fryTime;
}

@end

#pragma mark -

@interface FishFryer : Fryer

@property (nonatomic, assign, readonly) NSTimeInterval haddockFryTime;
@property (nonatomic, assign, readonly) NSTimeInterval codFryTime;
@property (nonatomic, assign, readonly) NSInteger fishFrierLimit;

@end

@implementation FishFryer

- (id)init {
    
    self = [super init];
    if (self) {
        
        _haddockFryTime = 90;
        _codFryTime = 80;
        _fishFrierLimit = 4;
    }
    
    return self;
}

- (NSTimeInterval)calculateFryTime {
    
    NSInteger fryRoundsHInt = self.order.haddocks.integerValue / self.fishFrierLimit;
    NSInteger fryRoundsCInt = self.order.cods.integerValue / self.fishFrierLimit;
    
    NSInteger modH = self.order.haddocks.integerValue % self.fishFrierLimit;
    NSInteger modC = self.order.cods.integerValue % self.fishFrierLimit;
    
    NSTimeInterval fryTime = fryRoundsHInt * self.haddockFryTime + fryRoundsCInt * self.codFryTime;
    
    if (modH + modC <= self.fishFrierLimit) {
        if (modH > 0) {
            fryTime += self.haddockFryTime;
        }
        else if (modC > 0) {
            fryTime += self.codFryTime;
        }
    }
    else {
        if (modH > 1) {
            fryTime += 2 * self.haddockFryTime;
        }
        else if (modC > 0) {
            fryTime += self.haddockFryTime + self.codFryTime;
        }
    }
    
    return fryTime;
}

- (void)processOrder {
    
    self.date = [self.date dateByAddingTimeInterval:self.delay];

    NSString *format = @"Begin Cooking %i %@";

    NSInteger haddocks = self.order.haddocks.integerValue;
    NSInteger cods = self.order.cods.integerValue;
    
    NSInteger fryRoundsH = (NSInteger)ceil((double)haddocks / (double)self.fishFrierLimit);
    for (int i = 0; i < fryRoundsH; i++) {

        NSInteger portion = haddocks > self.fishFrierLimit ? self.fishFrierLimit : haddocks;

        NSString *event = [NSString stringWithFormat:format, (long)portion, @"Haddock"];
        [self addTimeLineEvent:event date:self.date];

        self.date = [self.date dateByAddingTimeInterval: self.haddockFryTime];

        haddocks -= portion;
    }

    NSInteger fryRoundsC = (NSInteger)ceil((double)cods / (double)self.fishFrierLimit);
    for (int i = 0; i < fryRoundsC; i++) {

        NSInteger portion = cods > self.fishFrierLimit ? self.fishFrierLimit : cods;

        NSString *event = [NSString stringWithFormat:format, (long)portion, @"Cod"];
        [self addTimeLineEvent:event date:self.date];

        self.date = [self.date dateByAddingTimeInterval: self.codFryTime];
        
        cods -= portion;
    }
}

@end

#pragma mark -

@interface Kitchen : OrderProcessor

@property (nonatomic, retain, readonly) ChipsFryer *chipsFryer;
@property (nonatomic, retain, readonly) FishFryer *fishFryer;

@property (nonatomic, assign, readonly) NSTimeInterval mealServeTimeLimit;
@property (nonatomic, assign, readonly) NSTimeInterval orderServerTimeLimit;

- (BOOL)checkOrder;

- (void)processOrder;

- (void)serveOrder;

@end

@implementation Kitchen

- (id)init {
    
    self = [super init];
    if (self) {
        
        _chipsFryer = [ChipsFryer new];
        _fishFryer = [FishFryer new];
        
        _mealServeTimeLimit = 120;
        _orderServerTimeLimit = 600;
    }
    
    return self;
}

- (void)setOrder:(Order *)order {
    
    [super setOrder:order];
    
    self.date = order.date;
}

- (BOOL)checkOrder {
    
    BOOL shouldReject = YES;
    
    if (self.order) {
        
        self.chipsFryer.order = self.order;
        self.fishFryer.order = self.order;
        
        NSTimeInterval chipsFryTime = [self.chipsFryer calculateFryTime];
        NSTimeInterval fishFryTime = [self.fishFryer calculateFryTime];
        
        BOOL canServeChips = (chipsFryTime <= 2 * self.mealServeTimeLimit);
        BOOL canServeFish = (fishFryTime < 2 * self.mealServeTimeLimit);
        
        if (canServeChips && canServeFish) {
            
            NSTimeInterval fishReadyTime = [self.fishFryer.date timeIntervalSinceDate:self.date] + fishFryTime;
            NSTimeInterval chipsReadyTime = [self.chipsFryer.date timeIntervalSinceDate:self.date] + chipsFryTime;
            
            if ((fishReadyTime <= self.orderServerTimeLimit) && (chipsReadyTime <= self.orderServerTimeLimit)) {
                
                shouldReject = NO;
            }
        }
    }
    
    if (shouldReject) {
        [self addTimeLineEvent:[NSString stringWithFormat:@"%@ Rejected", self.order.orderNumber] date:self.order.date];
    }
    else {
        [self addTimeLineEvent:[NSString stringWithFormat:@"%@ Accepted", self.order.orderNumber] date:self.order.date];
    }
    
    return !shouldReject;
}

- (void)processOrder {
    
    NSTimeInterval chipsFryTime = [self.chipsFryer calculateFryTime];
    NSTimeInterval fishFryTime = [self.fishFryer calculateFryTime];
    
    NSTimeInterval fishFryDelay = chipsFryTime > fishFryTime ? chipsFryTime - fishFryTime : 0;
    NSTimeInterval chipsFryDelay = fishFryTime > chipsFryTime ? fishFryTime - chipsFryTime : 0;
    
    if (chipsFryDelay > fishFryDelay) {
        if (self.order.cods.integerValue + self.order.haddocks.integerValue > 0) {
            self.fishFryer.delay = fishFryDelay;
            [self.fishFryer processOrder];
            [self addTimeLineEvents:self.fishFryer.timeLine];
        }
        if (self.order.chips.integerValue > 0) {
            self.chipsFryer.delay = chipsFryDelay;
            [self.chipsFryer processOrder];
            [self addTimeLineEvents:self.chipsFryer.timeLine];
        }
    }
    else {
        if (self.order.chips.integerValue > 0) {
            self.chipsFryer.delay = chipsFryDelay;
            [self.chipsFryer processOrder];
            [self addTimeLineEvents:self.chipsFryer.timeLine];
        }
        if (self.order.cods.integerValue + self.order.haddocks.integerValue > 0) {
            self.fishFryer.delay = fishFryDelay;
            [self.fishFryer processOrder];
            [self addTimeLineEvents:self.fishFryer.timeLine];
        }
    }
    
    [self sortTimeLine];
}

- (void)serveOrder {
    
    NSDate *serveDate = MAX(self.fishFryer.date, self.chipsFryer.date);
    NSString *lineOut = [NSString stringWithFormat:@"Serve %@", self.order.orderNumber];
    [self addTimeLineEvent:lineOut date:serveDate];
}

@end

#pragma mark -

int main ( int argc, const char *argv[] ) {
    
    @autoreleasepool {
        
        Kitchen *kitchen = [Kitchen new];
        
        NSString *contents = openFile(@"input005.txt");

        NSInteger lineNumber = 0;
        NSString * line = readLine(contents, &lineNumber);
        
        while (line) {
            
            Order *order = [[Order alloc] initWithString:line];
            
            kitchen.order = order;
            
            if ([kitchen checkOrder]) {
                
                [kitchen processOrder];
                
                [kitchen serveOrder];
            }
            
            for (TimeLineEvent* event in kitchen.timeLine) {
                printLine(event.description);
            }
            
            line = readLine(contents, &lineNumber);
        }
    }
    
    return 0;
}


