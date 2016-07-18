//
//  User+CoreDataProperties.h
//  iVK
//
//  Created by Student on 7/18/16.
//  Copyright © 2016 Student. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface User (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *firstName;
@property (nullable, nonatomic, retain) NSNumber *id;
@property (nullable, nonatomic, retain) NSString *lastName;
@property (nullable, nonatomic, retain) NSSet<PhotoAlbum *> *createdPhotoAlbums;
@property (nullable, nonatomic, retain) NSSet<Photo *> *createdPhotos;
@property (nullable, nonatomic, retain) NSSet<Post *> *createdPosts;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addCreatedPhotoAlbumsObject:(PhotoAlbum *)value;
- (void)removeCreatedPhotoAlbumsObject:(PhotoAlbum *)value;
- (void)addCreatedPhotoAlbums:(NSSet<PhotoAlbum *> *)values;
- (void)removeCreatedPhotoAlbums:(NSSet<PhotoAlbum *> *)values;

- (void)addCreatedPhotosObject:(Photo *)value;
- (void)removeCreatedPhotosObject:(Photo *)value;
- (void)addCreatedPhotos:(NSSet<Photo *> *)values;
- (void)removeCreatedPhotos:(NSSet<Photo *> *)values;

- (void)addCreatedPostsObject:(Post *)value;
- (void)removeCreatedPostsObject:(Post *)value;
- (void)addCreatedPosts:(NSSet<Post *> *)values;
- (void)removeCreatedPosts:(NSSet<Post *> *)values;

@end

NS_ASSUME_NONNULL_END
