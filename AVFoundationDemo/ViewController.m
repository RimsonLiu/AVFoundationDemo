//
//  ViewController.m
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/23.
//  Copyright © 2020 rimson. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
}

- (void)initView {
    UIButton *choosePhotoButton = [[UIButton alloc] init];
    [choosePhotoButton setTitle:@"选择图片" forState:UIControlStateNormal];
    [choosePhotoButton setBackgroundColor:[UIColor blackColor]];
    UITapGestureRecognizer *tapChoosePhotoButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(choosePhoto)];
    [choosePhotoButton addGestureRecognizer:tapChoosePhotoButton];
    [self.view addSubview:choosePhotoButton];
    [choosePhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
    }];
    
    self.navigationController.navigationBar.hidden = NO;
}

#pragma mark - Action

- (void)choosePhoto {
    ELCImagePickerController *imagePickerController = [[ELCImagePickerController alloc] initImagePicker];
    imagePickerController.maximumImagesCount = INFINITY;
    imagePickerController.returnsImage = YES;
    imagePickerController.onOrder = YES;
    imagePickerController.imagePickerDelegate = self;
    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - ELCImagePickerControllerDelegate



- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
