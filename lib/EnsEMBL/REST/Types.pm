# A set of types used by the REST API namespaced to avoid coercsion collisions
package EnsEMBL::REST::Types;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'EnsRESTValueList', as 'ArrayRef[Value]';

coerce 'EnsRESTValueList' => from 'Value' => via { [$_] };

1;