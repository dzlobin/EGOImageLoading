//
//  EGOImageView.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/15/09.
//  Copyright (c) 2009-2010 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOImageView.h"
#import "EGOImageLoader.h"

@implementation EGOImageView
@synthesize imageURL, placeholderImage, delegate, progressDelegate;

- (id)initWithPlaceholderImage:(UIImage*)anImage {
	return [self initWithPlaceholderImage:anImage delegate:nil];	
}

- (id)initWithPlaceholderImage:(UIImage*)anImage delegate:(id<EGOImageViewDelegate>)aDelegate {
	if((self = [super initWithImage:anImage])) {
		self.placeholderImage = anImage;
		self.delegate = aDelegate;
	}
    
    self.bytesReceived = 0;
    self.expectedBytes = 0;
	
    return self;
}

- (void)setPlaceholderImage:(UIImage *)anImage {
    [anImage retain]; // must retain before releasing old, in case placeholderImage is same
    [placeholderImage release];
    placeholderImage = anImage;
    if(!imageURL) {
        self.image = placeholderImage;
    }
}

- (void)setImageURL:(NSURL *)aURL {
    self.bytesReceived = 0;
    self.expectedBytes = 0;
    
    EGOImageLoader *sharedImageLoader = [EGOImageLoader sharedImageLoader];
	if(imageURL) {
		[sharedImageLoader removeObserver:self forURL:imageURL];
		[imageURL release];
		imageURL = nil;
	}
	
	if(!aURL) {
		self.image = placeholderImage;
//		self.imageURL = nil;
		return;
	} else {
		imageURL = [aURL retain];
	}

	[sharedImageLoader removeObserver:self];
    
    // new logic
    if ([sharedImageLoader hasLoadedImageURL:aURL]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(){
            UIImage *anImage = [sharedImageLoader imageForURL:aURL shouldLoadWithObserver:self];
            if (anImage == nil) {
                // if image expired between hasLoadedImageURL check, and imageForURL call
                // loader callback will handle the request
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^(){
                if ([imageURL isEqual:aURL]) {
                    self.image = anImage;
                    if([delegate respondsToSelector:@selector(imageViewLoadedImage:loadedFromCache:)]) {
                        [delegate imageViewLoadedImage:self loadedFromCache:YES];
                    }
                } // else, different image was requested
            });
        });
    } else {
        [sharedImageLoader loadImageForURL:aURL observer:self];
		self.image = placeholderImage;
    }
    // old logic
//	UIImage* anImage = [sharedImageLoader imageForURL:aURL shouldLoadWithObserver:self];
//	if(anImage) {
//		self.image = anImage;
//
//		// trigger the delegate callback if the image was found in the cache
//		if([delegate respondsToSelector:@selector(imageViewLoadedImage:loadedFromCache:)]) {
//			[delegate imageViewLoadedImage:self loadedFromCache:NO];
//		}
//	} else {
//		self.image = placeholderImage;
//	}
}

#pragma mark -
#pragma mark Image loading

- (void)cancelImageLoad {
    EGOImageLoader *sharedImageLoader = [EGOImageLoader sharedImageLoader];
	[sharedImageLoader cancelLoadForURL:imageURL];
	[sharedImageLoader removeObserver:self forURL:imageURL];
    if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(didFinishImageDownload)]) {
        [self.progressDelegate didFinishImageDownload];
    }
}

- (void)beginImageDownload:(NSNotification *)notification
{
    if ([[notification userInfo] objectForKey:@"expectedLength"]) 
        self.expectedBytes = [[[notification userInfo] objectForKey:@"expectedLength"] longLongValue];
    
    if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(startedDownloadingImage)]) {
        [self.progressDelegate didBeginImageDownload];
    }
}

- (void)updateImageDownloadProgress:(NSNotification *)notification
{
    float progress;
    long long receivedLen;
    
    if ([[notification userInfo] objectForKey:@"progress"]) {
        receivedLen = [[[notification userInfo] objectForKey:@"progress"] longLongValue];
        
        self.bytesReceived = (self.bytesReceived + receivedLen);
        if(self.expectedBytes != NSURLResponseUnknownLength) {
            progress = (self.bytesReceived/(float)self.expectedBytes);
            NSLog(@"Progress is %f", progress);
            if (self.bytesReceived > self.expectedBytes) {
                NSLog(@"rec is %lli and exp is %lli", self.bytesReceived, self.expectedBytes);

            }
            if (self.progressDelegate && [self.progressDelegate respondsToSelector:@selector(didUpdateDownloadProgress:)]) {
                [self.progressDelegate didUpdateDownloadProgress:progress];
            }
            
        }
        
    }
}



- (void)imageLoaderDidLoad:(NSNotification*)notification {
    NSDictionary *userInfo = notification.userInfo;
	if(![[userInfo objectForKey:@"imageURL"] isEqual:imageURL]) return;

	UIImage* anImage = [userInfo objectForKey:@"image"];
	self.image = anImage;
	[self setNeedsDisplay];
	
	if([delegate respondsToSelector:@selector(imageViewLoadedImage:loadedFromCache:)]) {
		[delegate imageViewLoadedImage:self loadedFromCache:NO];
	}
    self.bytesReceived = 0;
    self.expectedBytes = 0;
}

- (void)imageLoaderDidFailToLoad:(NSNotification*)notification {
    NSDictionary *userInfo = notification.userInfo;
	if(![[userInfo objectForKey:@"imageURL"] isEqual:imageURL]) return;
	
	if([delegate respondsToSelector:@selector(imageViewFailedToLoadImage:error:)]) {
		[delegate imageViewFailedToLoadImage:self error:[userInfo objectForKey:@"error"]];
	}
    self.bytesReceived = 0;
    self.expectedBytes = 0;
    
}

#pragma mark -
- (void)dealloc {
	[[EGOImageLoader sharedImageLoader] removeObserver:self];
    self.delegate = nil;
	self.imageURL = nil;
	self.placeholderImage = nil;
    [super dealloc];
}

@end
