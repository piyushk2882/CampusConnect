// ignore_for_file: public_member_api_docs, document_ignores

import 'package:powersync/powersync.dart';

const schema = Schema([
  Table(
    'profiles',
    [
      Column.text('full_name'),
      Column.text('email'),
      Column.text('username'),
      Column.text('avatar_url'),
      Column.text('push_token'),
      Column.integer('is_verified'),
    ],
  ),
  Table(
    'posts',
    [
      Column.text('user_id'),
      Column.text('created_at'),
      Column.text('caption'),
      Column.text('updated_at'),
      Column.text('media'),
    ],
    indexes: [
      Index('user', [IndexedColumn('user_id')]),
    ],
  ),
  Table(
    'videos',
    [
      Column.text('owner_id'),
      Column.text('url'),
      Column.text('blur_hash'),
      Column.text('first_frame_url'),
    ],
    indexes: [
      Index('user', [IndexedColumn('owner_id')]),
    ],
  ),
  Table(
    'images',
    [
      Column.text('owner_id'),
      Column.text('url'),
      Column.text('blur_hash'),
    ],
    indexes: [
      Index('user', [IndexedColumn('owner_id')]),
    ],
  ),
  Table(
    'likes',
    [
      Column.text('user_id'),
      Column.text('comment_id'),
      Column.text('post_id'),
    ],
    indexes: [
      Index('user', [IndexedColumn('user_id')]),
      Index('post', [IndexedColumn('post_id')]),
      Index('comment', [IndexedColumn('comment_id')]),
    ],
  ),
  Table(
    'comments',
    [
      Column.text('post_id'),
      Column.text('user_id'),
      Column.text('content'),
      Column.text('created_at'),
      Column.text('replied_to_comment_id'),
    ],
    indexes: [
      Index('user', [IndexedColumn('user_id')]),
      Index('post', [IndexedColumn('post_id')]),
      Index('comment', [IndexedColumn('replied_to_comment_id')]),
    ],
  ),
  Table(
    'conversations',
    [
      Column.text('type'),
      Column.text('name'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
  ),
  Table(
    'participants',
    [
      Column.text('user_id'),
      Column.text('conversation_id'),
    ],
    indexes: [
      Index('conversation', [IndexedColumn('conversation_id')]),
      Index('user', [IndexedColumn('user_id')]),
    ],
  ),
  Table(
    'messages',
    [
      Column.text('conversation_id'),
      Column.text('from_id'),
      Column.text('type'),
      Column.text('message'),
      Column.text('reply_message_id'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.integer('is_read'),
      Column.integer('is_deleted'),
      Column.integer('is_edited'),
      Column.text('reply_message_username'),
      Column.text('reply_message_attachment_url'),
      Column.text('shared_post_id'),
    ],
    indexes: [
      Index('conversation', [IndexedColumn('conversation_id')]),
      Index('user', [IndexedColumn('from_id')]),
      Index('message', [IndexedColumn('reply_message_id')]),
      Index('post', [IndexedColumn('shared_post_id')]),
    ],
  ),
  Table(
    'attachments',
    [
      Column.text('message_id'),
      Column.text('title'),
      Column.text('text'),
      Column.text('title_link'),
      Column.text('image_url'),
      Column.text('thumb_url'),
      Column.text('author_name'),
      Column.text('author_link'),
      Column.text('asset_url'),
      Column.text('og_scrape_url'),
      Column.text('type'),
    ],
    indexes: [
      Index('message', [IndexedColumn('message_id')]),
    ],
  ),
  Table(
    'subscriptions',
    [
      Column.text('subscriber_id'),
      Column.text('subscribed_to_id'),
    ],
    indexes: [
      Index(
        'user',
        [IndexedColumn('subscriber_id'), IndexedColumn('subscribed_to_id')],
      ),
    ],
  ),
  Table(
    'stories',
    [
      Column.text('user_id'),
      Column.text('content_type'),
      Column.text('content_url'),
      Column.integer('duration'),
      Column.text('created_at'),
      Column.text('expires_at'),
    ],
    indexes: [
      Index('user', [IndexedColumn('user_id')]),
    ],
  ),
  Table(
    'projects',
    [
      Column.text('user_id'),
      Column.text('title'),
      Column.text('summary'),
      Column.text('github_link'),
      Column.text('researchpaper_link'),
      Column.text('pdf_url'),
      Column.text('domain'),
      Column.text('branch'),
      Column.text('year'),
      Column.text('guide'),
    ],
  ),
  Table(
    'ratings',
    [
      Column.text('user_id'),
      Column.text('project_id'),
      Column.integer('rating'),
      Column.text('review'), // Added review column
      Column.text('created_at'),
    ],
    indexes: [
      Index('project', [IndexedColumn('project_id')]),
      Index('user', [IndexedColumn('user_id')]),
    ],
  ),
  Table(
    'pins',
    [
      Column.text('user_id'),
      Column.text('project_id'),
    ],
    indexes: [
      Index('project_user', [
        IndexedColumn('user_id'),
        IndexedColumn('project_id'),
      ]),
    ],
  ),
  Table(
    'clubs',
    [
      Column.text('club_name'),
      Column.text('club_logo'),
      Column.text('club_description'),
      Column.text('president_name'),
      Column.text('president_image'),
      Column.text('vicepresident_name'),
      Column.text('vicepresident_image'),
      Column.text('club_email'),
    ],
  ),
  Table(
    'events',
    [
      Column.text('club_id'),
      Column.text('event_name'),
      Column.text('event_description'),
      Column.text('event_date'),
      Column.text('event_type'),
      Column.text('event_location'),
      Column.real('event_fees'),
      Column.integer('event_teamsize'),
      Column.text('event_posterimage'),
      Column.text('contact1_name'),
      Column.text('contact1_phn'),
      Column.text('contact1_role'),
      Column.text('contact2_name'),
      Column.text('contact2_phn'),
      Column.text('contact2_role'),
      Column.text('registration_url'),
      Column.text('event_time'),
    ],
  ),
  Table(
    'savedposts',
    [
      Column.text('user_id'),
      Column.text('post_id'),
    ],
    indexes: [
      Index('user', [IndexedColumn('user_id')]),
      Index('post', [IndexedColumn('post_id')]),
    ],
  ),
  Table(
    'club_hiring',
    [
      Column.text('club_id'),
      Column.text('roles'),
      Column.text('classes'),
      Column.text('created_at'),
    ],
    indexes: [
      Index('club', [IndexedColumn('club_id')]),
    ],
  ),
  Table(
    'club_applications',
    [
      Column.text('club_id'),
      Column.text('user_id'),
      Column.text('student_name'),
      Column.text('class'),
      Column.text('department'),
      Column.text('prn'),
      Column.text('phone'),
      Column.text('role_applied'),
      Column.text('resume_url'),
      Column.text('status'),
      Column.text('created_at'),
    ],
    indexes: [
      Index('club', [IndexedColumn('club_id')]),
    ],
  ),
  Table(
    'faculties',
    [
      Column.text('title_of_respect'),
      Column.text('fullname'),
      Column.text('department'),
      Column.text('designation'),
      Column.text('mobile_no'),
      Column.text('email'),
      Column.text('photo_url'),
    ],
  ),
]);
