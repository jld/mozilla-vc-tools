#require docker

  $ . $TESTDIR/hgext/reviewboard/tests/helpers.sh
  $ commonenv

  $ cd client
  $ echo foo > foo
  $ hg commit -A -m 'root commit'
  adding foo
  $ hg phase --public -r .

  $ adminbugzilla create-user author@example.com password 'Some Contributor'
  created user 6
  $ mozreview create-ldap-user author@example.com contributor 2001 'Some Contributor' --key-file ${MOZREVIEW_HOME}/keys/author@example.com --scm-level 1
  $ adminbugzilla create-user reviewer@example.com password 'Mozilla Reviewer [:reviewer]' --group editbugs
  created user 7
  $ adminbugzilla create-user reviewer2@example.com password 'Another Reviewer [:rev2]' --group editbugs
  created user 8
  $ adminbugzilla create-user troll@example.com password 'Reviewer Troll [:troll]' --group editbugs
  created user 9

Create a review request from a regular user

  $ exportbzauth author@example.com password
  $ bugzilla create-bug TestProduct TestComponent 'First Bug'

  $ echo initial > foo
  $ hg commit -m 'Bug 1 - Initial commit to review'
  $ hg --config bugzilla.username=author@example.com push > /dev/null

Adding a reviewer should result in a r? flag being set

  $ rbmanage add-reviewer 1 --user reviewer
  1 people listed on review request
  $ rbmanage publish 1

  $ bugzilla dump-bug 1
  Bug 1:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://*:$HGPORT1/r/1/ (glob)
      description: 'MozReview Request: bz://1/mynick'
      file_name: reviewboard-1-url.txt
      flags:
      - id: 1
        name: review
        requestee: reviewer@example.com
        setter: author@example.com
        status: '?'
      id: 1
      is_obsolete: false
      is_patch: false
      summary: 'MozReview Request: bz://1/mynick'
    blocks: []
    cc:
    - reviewer@example.com
    comments:
    - author: author@example.com
      id: 1
      tags: []
      text: ''
    - author: author@example.com
      id: 2
      tags: []
      text: 'Created attachment 1
  
        MozReview Request: bz://1/mynick
  
  
        /r/2 - Bug 1 - Initial commit to review
  
  
        Pull down this commit:
  
  
        hg pull -r 57755461e85f1e3e66738ec2d57f325249897409 http://*:$HGPORT/test-repo' (glob)
    component: TestComponent
    depends_on: []
    platform: All
    product: TestProduct
    resolution: ''
    status: UNCONFIRMED
    summary: First Bug

Adding a "Ship It" review will grant r+

  $ exportbzauth reviewer@example.com password
  $ rbmanage create-review 1 --body-top LGTM --public --ship-it
  created review 1

  $ bugzilla dump-bug 1
  Bug 1:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://*:$HGPORT1/r/1/ (glob)
      description: 'MozReview Request: bz://1/mynick'
      file_name: reviewboard-1-url.txt
      flags:
      - id: 1
        name: review
        requestee: null
        setter: reviewer@example.com
        status: +
      id: 1
      is_obsolete: false
      is_patch: false
      summary: 'MozReview Request: bz://1/mynick'
    blocks: []
    cc:
    - reviewer@example.com
    comments:
    - author: author@example.com
      id: 1
      tags: []
      text: ''
    - author: author@example.com
      id: 2
      tags: []
      text: 'Created attachment 1
  
        MozReview Request: bz://1/mynick
  
  
        /r/2 - Bug 1 - Initial commit to review
  
  
        Pull down this commit:
  
  
        hg pull -r 57755461e85f1e3e66738ec2d57f325249897409 http://*:$HGPORT/test-repo' (glob)
    - author: reviewer@example.com
      id: 3
      tags: []
      text: 'Comment on attachment 1
  
        MozReview Request: bz://1/mynick
  
  
        http://*:$HGPORT1/r/1/#review1 (glob)
  
  
        LGTM'
    component: TestComponent
    depends_on: []
    platform: All
    product: TestProduct
    resolution: ''
    status: UNCONFIRMED
    summary: First Bug

Adding a reply to the review will add a comment to Bugzilla

  $ exportbzauth author@example.com password
  $ rbmanage create-review-reply 1 1 --body-bottom 'Thanks!' --public
  created review reply 2

  $ bugzilla dump-bug 1
  Bug 1:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://*:$HGPORT1/r/1/ (glob)
      description: 'MozReview Request: bz://1/mynick'
      file_name: reviewboard-1-url.txt
      flags:
      - id: 1
        name: review
        requestee: null
        setter: reviewer@example.com
        status: +
      id: 1
      is_obsolete: false
      is_patch: false
      summary: 'MozReview Request: bz://1/mynick'
    blocks: []
    cc:
    - reviewer@example.com
    comments:
    - author: author@example.com
      id: 1
      tags: []
      text: ''
    - author: author@example.com
      id: 2
      tags: []
      text: 'Created attachment 1
  
        MozReview Request: bz://1/mynick
  
  
        /r/2 - Bug 1 - Initial commit to review
  
  
        Pull down this commit:
  
  
        hg pull -r 57755461e85f1e3e66738ec2d57f325249897409 http://*:$HGPORT/test-repo' (glob)
    - author: reviewer@example.com
      id: 3
      tags: []
      text: 'Comment on attachment 1
  
        MozReview Request: bz://1/mynick
  
  
        http://*:$HGPORT1/r/1/#review1 (glob)
  
  
        LGTM'
    - author: author@example.com
      id: 4
      tags: []
      text: 'http://*:$HGPORT1/r/1/#review2 (glob)
  
  
        Thanks!'
    component: TestComponent
    depends_on: []
    platform: All
    product: TestProduct
    resolution: ''
    status: UNCONFIRMED
    summary: First Bug

Ensure multiple reviewers works as expected

  $ exportbzauth author@example.com password
  $ bugzilla create-bug TestProduct TestComponent 'Multiple Reviewers'

  $ hg up -r 0 > /dev/null
  $ echo b2 > foo
  $ hg commit -m 'Bug 2 - Multiple reviewers'
  created new head
  $ hg --config bugzilla.username=author@example.com push > /dev/null

  $ rbmanage add-reviewer 3 --user reviewer --user rev2
  2 people listed on review request
  $ rbmanage publish 3

  $ bugzilla dump-bug 2
  Bug 2:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://*:$HGPORT1/r/3/ (glob)
      description: 'MozReview Request: bz://2/mynick'
      file_name: reviewboard-3-url.txt
      flags:
      - id: 2
        name: review
        requestee: reviewer2@example.com
        setter: author@example.com
        status: '?'
      - id: 3
        name: review
        requestee: reviewer@example.com
        setter: author@example.com
        status: '?'
      id: 2
      is_obsolete: false
      is_patch: false
      summary: 'MozReview Request: bz://2/mynick'
    blocks: []
    cc:
    - reviewer2@example.com
    - reviewer@example.com
    comments:
    - author: author@example.com
      id: 5
      tags: []
      text: ''
    - author: author@example.com
      id: 6
      tags: []
      text: 'Created attachment 2
  
        MozReview Request: bz://2/mynick
  
  
        /r/4 - Bug 2 - Multiple reviewers
  
  
        Pull down this commit:
  
  
        hg pull -r d17099d7ee43e288f43e0210edc71b9782f92b77 http://*:$HGPORT/test-repo' (glob)
    component: TestComponent
    depends_on: []
    platform: All
    product: TestProduct
    resolution: ''
    status: UNCONFIRMED
    summary: Multiple Reviewers

Removing a reviewer should remove their review flag

  $ rbmanage remove-reviewer 3 --user rev2
  1 people listed on review request

  $ rbmanage publish 3

  $ bugzilla dump-bug 2
  Bug 2:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://*:$HGPORT1/r/3/ (glob)
      description: 'MozReview Request: bz://2/mynick'
      file_name: reviewboard-3-url.txt
      flags:
      - id: 3
        name: review
        requestee: reviewer@example.com
        setter: author@example.com
        status: '?'
      id: 2
      is_obsolete: false
      is_patch: false
      summary: 'MozReview Request: bz://2/mynick'
    blocks: []
    cc:
    - reviewer2@example.com
    - reviewer@example.com
    comments:
    - author: author@example.com
      id: 5
      tags: []
      text: ''
    - author: author@example.com
      id: 6
      tags: []
      text: 'Created attachment 2
  
        MozReview Request: bz://2/mynick
  
  
        /r/4 - Bug 2 - Multiple reviewers
  
  
        Pull down this commit:
  
  
        hg pull -r d17099d7ee43e288f43e0210edc71b9782f92b77 http://*:$HGPORT/test-repo' (glob)
    - author: author@example.com
      id: 7
      tags: []
      text: 'Comment on attachment 2
  
        MozReview Request: bz://2/mynick
  
  
        /r/4 - Bug 2 - Multiple reviewers
  
  
        Pull down this commit:
  
  
        hg pull -r d17099d7ee43e288f43e0210edc71b9782f92b77 http://*:$HGPORT/test-repo' (glob)
    component: TestComponent
    depends_on: []
    platform: All
    product: TestProduct
    resolution: ''
    status: UNCONFIRMED
    summary: Multiple Reviewers

Removing all reviewers should remove all flags

  $ rbmanage remove-reviewer 3 --user reviewer
  0 people listed on review request

  $ rbmanage publish 3

  $ bugzilla dump-bug 2
  Bug 2:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://*:$HGPORT1/r/3/ (glob)
      description: 'MozReview Request: bz://2/mynick'
      file_name: reviewboard-3-url.txt
      flags: []
      id: 2
      is_obsolete: false
      is_patch: false
      summary: 'MozReview Request: bz://2/mynick'
    blocks: []
    cc:
    - reviewer2@example.com
    - reviewer@example.com
    comments:
    - author: author@example.com
      id: 5
      tags: []
      text: ''
    - author: author@example.com
      id: 6
      tags: []
      text: 'Created attachment 2
  
        MozReview Request: bz://2/mynick
  
  
        /r/4 - Bug 2 - Multiple reviewers
  
  
        Pull down this commit:
  
  
        hg pull -r d17099d7ee43e288f43e0210edc71b9782f92b77 http://*:$HGPORT/test-repo' (glob)
    - author: author@example.com
      id: 7
      tags: []
      text: 'Comment on attachment 2
  
        MozReview Request: bz://2/mynick
  
  
        /r/4 - Bug 2 - Multiple reviewers
  
  
        Pull down this commit:
  
  
        hg pull -r d17099d7ee43e288f43e0210edc71b9782f92b77 http://*:$HGPORT/test-repo' (glob)
    - author: author@example.com
      id: 8
      tags: []
      text: 'Comment on attachment 2
  
        MozReview Request: bz://2/mynick
  
  
        /r/4 - Bug 2 - Multiple reviewers
  
  
        Pull down this commit:
  
  
        hg pull -r d17099d7ee43e288f43e0210edc71b9782f92b77 http://*:$HGPORT/test-repo' (glob)
    component: TestComponent
    depends_on: []
    platform: All
    product: TestProduct
    resolution: ''
    status: UNCONFIRMED
    summary: Multiple Reviewers

review? sticks around when 1 person grants review

  $ exportbzauth author@example.com password
  $ bugzilla create-bug TestProduct TestComponent 'More Multiple Reviewers'

  $ hg up -r 0 > /dev/null
  $ echo more_multiple_reviewers > foo
  $ hg commit -m 'Bug 3 - More multiple reviewers'
  created new head
  $ hg --config bugzilla.username=author@example.com push > /dev/null

  $ rbmanage add-reviewer 5 --user reviewer --user rev2
  2 people listed on review request
  $ rbmanage publish 5

  $ exportbzauth reviewer@example.com password
  $ rbmanage create-review 5 --body-top 'land it!' --public --ship-it
  created review 3

  $ bugzilla dump-bug 3
  Bug 3:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://*:$HGPORT1/r/5/ (glob)
      description: 'MozReview Request: bz://3/mynick'
      file_name: reviewboard-5-url.txt
      flags:
      - id: 4
        name: review
        requestee: reviewer2@example.com
        setter: author@example.com
        status: '?'
      - id: 5
        name: review
        requestee: null
        setter: reviewer@example.com
        status: +
      id: 3
      is_obsolete: false
      is_patch: false
      summary: 'MozReview Request: bz://3/mynick'
    blocks: []
    cc:
    - reviewer2@example.com
    - reviewer@example.com
    comments:
    - author: author@example.com
      id: 9
      tags: []
      text: ''
    - author: author@example.com
      id: 10
      tags: []
      text: 'Created attachment 3
  
        MozReview Request: bz://3/mynick
  
  
        /r/6 - Bug 3 - More multiple reviewers
  
  
        Pull down this commit:
  
  
        hg pull -r fb992de2921c9dd3117becff799b1e41e0dc4827 http://*:$HGPORT/test-repo' (glob)
    - author: reviewer@example.com
      id: 11
      tags: []
      text: 'Comment on attachment 3
  
        MozReview Request: bz://3/mynick
  
  
        http://*:$HGPORT1/r/5/#review3 (glob)
  
  
        land it!'
    component: TestComponent
    depends_on: []
    platform: All
    product: TestProduct
    resolution: ''
    status: UNCONFIRMED
    summary: More Multiple Reviewers

Random users can come along and grant review

  $ exportbzauth author@example.com password
  $ bugzilla create-bug TestProduct TestComponent 'Unrelated Reviewers'

  $ hg up -r 0 > /dev/null
  $ echo unrelated_reviewer > foo
  $ hg commit -m 'Bug 4 - Unrelated Reviewers'
  created new head
  $ hg --config bugzilla.username=author@example.com push > /dev/null

  $ rbmanage add-reviewer 7 --user reviewer
  1 people listed on review request
  $ rbmanage publish 7

  $ exportbzauth troll@example.com password
  $ rbmanage create-review 7 --body-top 'I am always watching' --public --ship-it
  created review 4

  $ bugzilla dump-bug 4
  Bug 4:
    attachments:
    - attacher: author@example.com
      content_type: text/x-review-board-request
      data: http://*:$HGPORT1/r/7/ (glob)
      description: 'MozReview Request: bz://4/mynick'
      file_name: reviewboard-7-url.txt
      flags:
      - id: 6
        name: review
        requestee: reviewer@example.com
        setter: author@example.com
        status: '?'
      - id: 7
        name: review
        requestee: null
        setter: troll@example.com
        status: +
      id: 4
      is_obsolete: false
      is_patch: false
      summary: 'MozReview Request: bz://4/mynick'
    blocks: []
    cc:
    - reviewer@example.com
    comments:
    - author: author@example.com
      id: 12
      tags: []
      text: ''
    - author: author@example.com
      id: 13
      tags: []
      text: 'Created attachment 4
  
        MozReview Request: bz://4/mynick
  
  
        /r/8 - Bug 4 - Unrelated Reviewers
  
  
        Pull down this commit:
  
  
        hg pull -r 13295ed17a69bdcef2644c0ab72736292db21b80 http://*:$HGPORT/test-repo' (glob)
    - author: troll@example.com
      id: 14
      tags: []
      text: 'Comment on attachment 4
  
        MozReview Request: bz://4/mynick
  
  
        http://*:$HGPORT1/r/7/#review4 (glob)
  
  
        I am always watching'
    component: TestComponent
    depends_on: []
    platform: All
    product: TestProduct
    resolution: ''
    status: UNCONFIRMED
    summary: Unrelated Reviewers

  $ cd ..

Cleanup

  $ mozreview stop
  stopped 8 containers
