//
//  avMessageCell.m
//  av
//
//  Created by Utku ALTINKAYA on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "chatMessageCell.h"

@interface chatMessageCell()
@property (nonatomic,strong) UIImageView *balloonView;
@property (nonatomic,strong) UILabel *msgLabel;
@end



@implementation chatMessageCell

@synthesize message = _message;
@synthesize play = _play;

@synthesize balloonView = _balloonView;
@synthesize msgLabel = _msgLabel;

#pragma mark Class Methods

+ (CGFloat)sizeForMessage:(XMPPMessageCoreDataObject *)message {
	CGSize size = [message.body sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(240.0, 480.0) lineBreakMode:UILineBreakModeWordWrap];
    
    NSLog(@"Size For Message: %f Body: %@",size.height+15,message.body);
    return size.height + 15;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSLog(@"Initialize Edildi");


        //[self addSubview:self.infoLabel];
        
        //self.avatarImage = [[[uaRemoteImage alloc] init] autorelease];
        //[self addSubview:self.avatarImage];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) updateFrames 
{    
    
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _balloonView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _balloonView.tag = 1;
    
    _msgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _msgLabel.backgroundColor = [UIColor clearColor];
    _msgLabel.tag = 2;
    _msgLabel.numberOfLines = 0;
    _msgLabel.lineBreakMode = UILineBreakModeWordWrap;
    _msgLabel.font = [UIFont systemFontOfSize:14.0];
    
    UIView *messageLabel = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
    messageLabel.tag = 0;
    [messageLabel addSubview:_balloonView];
    [messageLabel addSubview:_msgLabel];
    [self.contentView addSubview:messageLabel];
    
    
    /////////////////////////////////////////////
    
    self.balloonView = (UIImageView *)[[self.contentView viewWithTag:0] viewWithTag:1];
    self.msgLabel = (UILabel *)[[self.contentView viewWithTag:0] viewWithTag:2];
    
    CGSize size = [self.message.body sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(240.0f, 480.0f) lineBreakMode:UILineBreakModeWordWrap];
    UIImage *balloon;
    if (self.message.selfReplied == [NSNumber numberWithInt:1]) 
    {
        //NSLog(@"Self Message");
        self.balloonView.frame = CGRectMake(320.0f - (size.width + 28.0f), 2.0f, size.width + 28.0f, size.height + 15.0f);
		balloon = [[UIImage imageNamed:@"green.png"] stretchableImageWithLeftCapWidth:24 topCapHeight:15];
		self.msgLabel.frame = CGRectMake(307.0f - (size.width + 5.0f), 8.0f, size.width + 5.0f, size.height);
    } else {
        //NSLog(@"Other Message");
        self.balloonView.frame = CGRectMake(0.0, 2.0, size.width + 28, size.height + 15);
		balloon = [[UIImage imageNamed:@"grey.png"] stretchableImageWithLeftCapWidth:24 topCapHeight:15];
		self.msgLabel.frame = CGRectMake(16, 8, size.width + 5, size.height);
    } 
    
    self.balloonView.image = balloon;
	self.msgLabel.text = self.message.body;
}

- (void) setMessage:(XMPPMessageCoreDataObject *)message
{
    NSLog(@"SetMessageCell Geldii");
    _message = message;
    //self.textLabel.text = self.message.body;
    [self updateFrames];
    //[self.avatarImage loadFromUrl:[NSURL URLWithString:self.message.avatar.imageURL]];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}


@end
