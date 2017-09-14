#!/usr/bin/perl

#
# rel2abs.t
#


use strict ;
use Test ;
use Cwd;
use File::PathConvert qw( setfstype rel2abs );

my @data ;

BEGIN {
   @data = (
     # OS       INPUT             BASE                       OUTPUT                   
     [ 'Win32', 'temp\\..',       'C:\\',                    'C:\\'                    ],
     [ 'Win32', 'temp\\..',       'C:\\a',                   'C:\\a'                   ],
     [ 'Win32', 'temp\\..',       'C:\\a\\',                 'C:\\a\\'                 ],
     [ 'Win32', 'temp\\..\\',     'C:\\a',                   'C:\\a\\'                 ],
     [ 'Win32', 'temp\\..\\',     'C:\\a\\',                 'C:\\a\\'                 ],
     [ 'Win32', '..\\temp\\..',   'C:\\',                    'C:\\'                    ],
     [ 'Win32', '..\\temp\\..',   'C:\\a',                   'C:\\'                    ],
     [ 'Win32', '..\\temp\\..',   'C:\\a\\',                 'C:\\'                    ],
     [ 'Win32', 'temp\\..',       '\\\\prague_main\\work\\', '\\\\prague_main\\work\\' ],
     [ 'Win32', '..\\temp\\..',   '\\\\prague_main\\work\\', '\\\\prague_main\\work\\' ],
     [ 'Win32', 'temp\\..',       '\\\\prague_main\\work',   '\\\\prague_main\\work\\' ],
     [ 'Win32', '..\\temp\\..',   '\\\\prague_main\\work',   '\\\\prague_main\\work\\' ],

     [ 'other', 't4',             '/t1/t2/t3',               '/t1/t2/t3/t4'            ],
     [ 'other', 't4/t5',          '/t1/t2/t3',               '/t1/t2/t3/t4/t5'         ],
     [ 'other', '.',              '/t1/t2/t3',               '/t1/t2/t3'               ],
     [ 'other', '..',             '/t1/t2/t3',               '/t1/t2'                  ],
     [ 'other', '../t4',          '/t1/t2/t3',               '/t1/t2/t4'               ],
     [ 'other', '../../t5',       '/t1/t2/t3',               '/t1/t5'                  ],
     [ 'other', '../../../t6',    '/t1/t2/t3',               '/t6'                     ],
     [ 'other', '../../../../t7', '/t1/t2/t3',               '/t7'                     ],
     [ 'other', '../t4/t5/../t6', '/t1/t2/t3',               '/t1/t2/t4/t6'            ],
     [ 'other', '../t1/..',       '/t1/t2/t3',               '/t1/t2'                  ],
     [ 'other', '../t1/..',       '/',                       '/'                       ],
     [ 'other', '/t1',            '/t1/t2/t3',               '/t1'                     ],
   );

   plan tests => ( $#data + 1 ) ;
}

my $oldfsspec = '' ;

my $i ;

for ($i = 0 ; $i <= $#data ; ++$i )
{
   my( $fsspec, $in, $base, $expected ) = @{$data[ $i ] } ;
   die '$fsspec undefined'
      unless defined( $fsspec ) ;
   die '$in undefined'
      unless defined( $in ) ;
   die '$base undefined'
      unless defined( $base ) ;
   die '$expected undefined'
      unless defined( $expected ) ;

   if ( $fsspec ne $oldfsspec ) 
   {
      setfstype( $fsspec ) ;
      $oldfsspec= $fsspec ;
   }
   ok( 
      rel2abs($in, $base), 
      $expected, 
      "rel2abs( \"$in\", \"$base\" ) for \"$fsspec\"" 
   ) ;
}
