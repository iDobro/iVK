//
//  IVKNewsViewController.m
//  iVK
//
//  Created by Student on 7/8/16.
//  Copyright © 2016 Student. All rights reserved.
//

#import "IVKFeedViewController.h"
#import "User.h"
#import "Photo.h"
#import "PhotoAlbum.h"
#import "PhotoPost.h"
#import "IVKSessionDataManager.h"
#import "AppDelegate.h"
#import "NSManagedObjectContext+EasyAccess.h"
#import "PostTableViewCell.h"
@import CoreText;


@implementation IVKFeedViewController 
-(void) viewDidLoad{
    [super viewDidLoad];
    self.feedItems = [[NSMutableArray alloc] init];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self getFeedItems];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    //[self.tableView registerClass:[PostTableViewCell class] forCellReuseIdentifier:@"PostTableViewCell"];
    UINib *nib =  [UINib nibWithNibName:@"PostTableViewCell" bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PostTableViewCell"];
    [self.view addSubview:self.tableView];
}

-(void)getFeedItems {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    [IVKSessionDataManager GETRequestWithURL:@"https://api.vk.com/method/newsfeed.get" parameters:@{@"access_token" : token} handler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSDictionary *feedItemsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSArray *profiles = [[feedItemsDictionary objectForKey:@"response"] objectForKey:@"profiles"];
        for (NSDictionary *itemDict in profiles){                                                               /*vinesti v peremennuy*/
            User *object = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[NSManagedObjectContext defaultContext]];
            object.id = itemDict[@"uid"];
            object.firstName = itemDict[@"first_name"];
            object.lastName = itemDict[@"last_name"];
        }
        
        NSArray *items = [[feedItemsDictionary objectForKey:@"response"] objectForKey:@"items"];
        for (NSDictionary *item in  items) {
            NSDictionary *attachmentDict = item[@"attachment"];
            NSString *type = attachmentDict[@"type"];
            
            if([type isEqualToString:@"photo"]){
                NSNumber *photoId = attachmentDict[@"photo"][@"pid"];
                NSFetchRequest *photoFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
                photoFetchRequest.predicate = [NSPredicate predicateWithFormat:@"id == %@", photoId];
                [photoFetchRequest setFetchLimit:1];
                NSArray *photoFetchResult = [[NSManagedObjectContext defaultContext] executeFetchRequest:photoFetchRequest error:nil];
                Photo *photoObj =[photoFetchResult firstObject];

                if (photoObj == nil) {
                    photoObj = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:[NSManagedObjectContext defaultContext]];
                    
                    photoObj.id = attachmentDict[@"photo"][@"pid"];
                    photoObj.url = attachmentDict[@"photo"][@"src"];
                    photoObj.width = attachmentDict[@"photo"][@"width"];
                    photoObj.height = attachmentDict[@"photo"][@"height"];
                    photoObj.text = attachmentDict[@"photo"][@"text"];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                        
                        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[photoObj url]]];
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSString *stringPath = [[NSUUID UUID] UUIDString];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsDirectory = paths[0];
                        //NSLog(@"%@", documentsDirectory);
                        NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", stringPath]];
                        [fileManager createFileAtPath:fullPath contents:imageData attributes:nil];
                        photoObj.filePath = stringPath;
                    });
                }
                
                NSTimeInterval timeInterval = [attachmentDict[@"photo"][@"created"] doubleValue];
                photoObj.created = [NSDate dateWithTimeIntervalSince1970:timeInterval];
                
                NSNumber *ownerId = attachmentDict[@"photo"][@"owner_id"];
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"User"];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"id == %@", ownerId];
                [fetchRequest setFetchLimit:1];
                NSArray *fetchResult = [[NSManagedObjectContext defaultContext] executeFetchRequest:fetchRequest error:nil];
                User *owner = [fetchResult firstObject];
                
                if(owner != nil){
                    [owner addCreatedPhotosObject:photoObj];
                    [photoObj setOwner:owner];
                }
                
                if([self photoPostNotExist:item[@"post_id"]]){
                PhotoPost *photoPostObj = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoPost" inManagedObjectContext:[NSManagedObjectContext defaultContext]];
                photoPostObj.id = item[@"post_id"];
                photoPostObj.text = item[@"text"];
                timeInterval = [item[@"date"] doubleValue];
                photoPostObj.created = [NSDate dateWithTimeIntervalSince1970:timeInterval];
                photoPostObj.type = type;
                [photoPostObj addPhotosObject:photoObj];
                [photoObj addWasPostedInObject:photoPostObj];
                    
                }
            }
        }
        
        [[NSManagedObjectContext defaultContext] save:nil];
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PhotoPost"];
        NSArray *arr = [[NSManagedObjectContext defaultContext] executeFetchRequest:fetchRequest error:nil];
        [self.feedItems setArray:arr];
        
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.feedItems count];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    /*PhotoPost *item = self.feedItems[indexPath.row];
   
    NSString *text = item.text;
    UIImage *image = item.image;
    
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    
    CGRect rect = [text boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    
    return image.size.height + rect.size.height;*/
    
    return UITableViewAutomaticDimension;
    
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostTableViewCell" forIndexPath:indexPath];
    cell.post = self.feedItems[indexPath.row];
    return cell;
}

-(BOOL)photoPostNotExist:(NSNumber *)postId{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PhotoPost"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"id == %@", postId];
    [fetchRequest setFetchLimit:1];
    NSArray *array = [[NSManagedObjectContext defaultContext] executeFetchRequest:fetchRequest error:nil];
    PhotoPost *photoPost = [array firstObject];
    
    if(photoPost == nil){
        return YES;
    }else{
        return NO;
    }
}
@end


