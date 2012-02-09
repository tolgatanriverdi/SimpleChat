//
//  avMessageCell.m
//  av
//
//  Created by Utku ALTINKAYA on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

//TODO File Transfer Icin Progress Bar Eklenecek

#import "chatMessageCell.h"
#import "XMPPMessageUserCoreDataObject.h"

@interface chatMessageCell()
@property (nonatomic,strong) UIImageView *balloonView;
@property (nonatomic,strong) UILabel *msgLabel;
@property (nonatomic,strong) UIButton *viewDownloadButton;
@property (nonatomic,strong) NSString* mediaViewButtonStr;
@end



@implementation chatMessageCell

@synthesize message = _message;
@synthesize play = _play;

@synthesize balloonView = _balloonView;
@synthesize msgLabel = _msgLabel;
@synthesize viewDownloadButton = _viewDownloadButton;
@synthesize messageIndex = _messageIndex;
@synthesize buttonDelegate = _buttonDelegate;
@synthesize mediaViewButtonStr = _mediaViewButtonStr;


#pragma mark Class Methods

+ (CGFloat)sizeForMessage:(XMPPMessageCoreDataObject *)message {
	CGSize size = [message.body sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(240.0, 480.0) lineBreakMode:UILineBreakModeWordWrap];
    
    //NSLog(@"Size For Message: %f Body: %@",size.height+15,message.body);
    CGFloat cellSize;
    if ([message.type isEqualToString:@"chat"]) {
        cellSize = size.height +15;
    } else {
        cellSize = 80.0;
    }
    return cellSize;
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

-(void) viewPressed
{
    NSLog(@"View Button Pressed");
    [self.buttonDelegate chatCellViewButtonPressed:self.message];
}

-(void) downloadPressed
{
    //NSLog(@"Download Button Pressed");
    //NSString *thumbnailFileName = 
    NSDictionary *info;
    if ([self.message.type isEqualToString:@"image"]) {
        NSString *fromUser = self.message.whoOwns.jidStr;
        info = [NSDictionary dictionaryWithObjectsAndKeys:@"image",@"type",self.message.body,@"thumbnailFileName",fromUser,@"fromUser", nil];
    } else if ([self.message.type isEqualToString:@"audio"]) {
        NSString *fromUser = self.message.whoOwns.jidStr;
        info = [NSDictionary dictionaryWithObjectsAndKeys:@"audio",@"type",self.message.body,@"fileName",fromUser,@"fromUser", nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadMedia" object:nil userInfo:info];

}

-(void) updateFrames 
{   
    //NSLog(@"[ChatMessageCel] Index: %d Body: %@",_messageIndex,_message.body);
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _balloonView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _balloonView.tag = 1;
    
    
    UIView *messageLabel = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
    messageLabel.tag = 0;
    [messageLabel addSubview:_balloonView];
    if([self.message.type isEqualToString:@"chat"]) {
        
        _msgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _msgLabel.backgroundColor = [UIColor clearColor];
        _msgLabel.tag = 2;
        _msgLabel.numberOfLines = 0;
        _msgLabel.lineBreakMode = UILineBreakModeWordWrap;
        _msgLabel.font = [UIFont systemFontOfSize:14.0];
        
        [messageLabel addSubview:_msgLabel];
    } else if ([self.message.type isEqualToString:@"coordinate"] || [self.message.type isEqualToString:@"contact"]) { 
         NSLog(@"Coordinate & Contact View Butonu Ekleniyor");
        _viewDownloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _viewDownloadButton.tag = 3;
        [messageLabel addSubview:_viewDownloadButton];
    } else {
        if ((self.message.actualData && self.message.selfReplied) || self.message.selfReplied == [NSNumber numberWithInt:0]) 
        {
            NSLog(@"View Butonu Ekleniyor");
            _viewDownloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            _viewDownloadButton.tag = 3;
            [messageLabel addSubview:_viewDownloadButton];
        }
    }

    [self.contentView addSubview:messageLabel];
    
    
    /////////////////////////////////////////////
    
    self.balloonView = (UIImageView *)[[self.contentView viewWithTag:0] viewWithTag:1];
    if ([self.message.type isEqualToString:@"chat"]) {
        self.msgLabel = (UILabel *)[[self.contentView viewWithTag:0] viewWithTag:2];
    } else if ([self.message.type isEqualToString:@"coordinate"] || [self.message.type isEqualToString:@"contact"]) {
        self.viewDownloadButton = (UIButton*)[[self.contentView viewWithTag:0] viewWithTag:3];
    } else {
        if ((self.message.actualData && self.message.selfReplied) || self.message.selfReplied == [NSNumber numberWithInt:0]) {
            //NSLog(@"ViewDownload Button Listeye Ekleniyor");
            self.viewDownloadButton = (UIButton*)[[self.contentView viewWithTag:0] viewWithTag:3];
        }
    }
    
    CGSize size = [self.message.body sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(240.0f, 480.0f) lineBreakMode:UILineBreakModeWordWrap];
    UIImage *balloon;

    if (self.message.selfReplied == [NSNumber numberWithInt:1]) 
    {
        if ([self.message.type isEqualToString:@"chat"]) {
            //NSLog(@"Self Message");
            self.balloonView.frame = CGRectMake(320.0f - (size.width + 28.0f), 2.0f, size.width + 28.0f, size.height + 15.0f);
            balloon = [[UIImage imageNamed:@"green.png"] stretchableImageWithLeftCapWidth:24 topCapHeight:15];
            self.msgLabel.frame = CGRectMake(307.0f - (size.width + 5.0f), 8.0f, size.width + 5.0f, size.height); 
        } else {
            self.balloonView.frame = CGRectMake(240.0, 8.0, 60.0, 60.0);
            balloon = [UIImage imageWithData:self.message.thumbnail];
            
            if (self.message.actualData || [self.message.type isEqualToString:@"coordinate"]) {
                self.viewDownloadButton.frame = CGRectMake(160, 34.0, 60.0, 30.0);
                [self.viewDownloadButton setTitle:_mediaViewButtonStr forState:UIControlStateNormal];
                [self.viewDownloadButton addTarget:self action:@selector(viewPressed) forControlEvents:UIControlEventTouchUpInside];
            }
        }

    } else {
        if ([self.message.type isEqualToString:@"chat"]) {
            //NSLog(@"Other Message");
            self.balloonView.frame = CGRectMake(0.0, 2.0, size.width + 28, size.height + 15);
            balloon = [[UIImage imageNamed:@"grey.png"] stretchableImageWithLeftCapWidth:24 topCapHeight:15];
            self.msgLabel.frame = CGRectMake(16, 8, size.width + 5, size.height);
        } else {
            self.balloonView.frame = CGRectMake(5.0, 8.0, 60.0, 65.0);
            balloon = [UIImage imageWithData:self.message.thumbnail];
            
            if (!self.message.actualData && ![self.message.type isEqualToString:@"coordinate"] && ![self.message.type isEqualToString:@"contact"]) {
                //NSLog(@"Actual Data Yok");
                self.viewDownloadButton.frame = CGRectMake(100, 34.0, 100.0, 30.0);
                [self.viewDownloadButton setTitle:@"Download" forState:UIControlStateNormal];
                [self.viewDownloadButton addTarget:self action:@selector(downloadPressed) forControlEvents:UIControlEventTouchUpInside];
            } else {
                //NSLog(@"Actual Data Var");
                self.viewDownloadButton.frame = CGRectMake(100, 34.0, 60.0, 30.0);
                [self.viewDownloadButton setTitle:_mediaViewButtonStr forState:UIControlStateNormal];
                [self.viewDownloadButton addTarget:self action:@selector(viewPressed) forControlEvents:UIControlEventTouchUpInside];
            }
        }

    } 
    
    self.balloonView.image = balloon;
    if ([self.message.type isEqualToString:@"chat"]) {
        self.msgLabel.text = self.message.body;
    }

}

- (void) setMessage:(XMPPMessageCoreDataObject *)message
{
    //NSLog(@"SetMessageCell Geldii");
    _message = message;
    
    if (_message.type == @"image") {
        _mediaViewButtonStr = @"View";
    } else if (_message.type == @"audio") {
        _mediaViewButtonStr = @"Play";
    } else if(_message.type == @"coordinate") { 
        _mediaViewButtonStr = @"View";
    } else if (_message.type == @"contact") {
        _mediaViewButtonStr = @"Add";
    } else {
        _mediaViewButtonStr = @"";
    }
    
    [self updateFrames];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}


-(void) prepareForReuse
{
    for (UIView *view in [self.contentView subviews])
    {
        [view removeFromSuperview];
    }
}


@end
