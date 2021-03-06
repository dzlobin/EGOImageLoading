//
//  EGOImageView.h
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

#import <UIKit/UIKit.h>
#import "EGOImageLoader.h"

@protocol EGOImageViewDelegate;
@protocol EGOImageViewDownloadProgressDelegate;

@interface EGOImageView : UIImageView<EGOImageLoaderObserver> {
@private
	NSURL* imageURL;
	UIImage* placeholderImage;
	id<EGOImageViewDelegate> delegate;
    id<EGOImageViewDownloadProgressDelegate> progressDelegate;
}

- (id)initWithPlaceholderImage:(UIImage*)anImage; // delegate:nil
- (id)initWithPlaceholderImage:(UIImage*)anImage delegate:(id<EGOImageViewDelegate>)aDelegate;

- (void)cancelImageLoad;

- (void)updateImageDownloadProgress:(NSNotification *)notification; //a notification is sent by EGOImageLoader containing the size of the latest recieved data, used to measure download progress
- (void)beginImageDownload:(NSNotification *)notification; //a notification is sent by EGOImageLoader containing the total size of the download data, used to measure download progress


@property(nonatomic,retain) NSURL* imageURL;
@property(nonatomic,retain) UIImage* placeholderImage;
@property(nonatomic,assign) id<EGOImageViewDelegate> delegate;
@property(nonatomic,assign) id<EGOImageViewDownloadProgressDelegate> progressDelegate;

@property long long expectedBytes; // used to measure file upload progress, represents the total file size
@property long long bytesReceived; // also used to measure file upload progress, represents the running total bytes recieved for a particular upload
@end

@protocol EGOImageViewDelegate<NSObject>
@optional
- (void)imageViewLoadedImage:(EGOImageView*)imageView loadedFromCache:(BOOL)loadedFromCache;
- (void)imageViewFailedToLoadImage:(EGOImageView*)imageView error:(NSError*)error;
@end

@protocol EGOImageViewDownloadProgressDelegate<NSObject>
@optional
- (void)didUpdateDownloadProgress:(float)progress;
- (void)didBeginImageDownload;
- (void)didFinishImageDownload;
@end
