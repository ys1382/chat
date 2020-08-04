//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

//void demo_donna_donna();
#include<stdint.h>

int curve25519_donna(uint8_t *mypublic, const uint8_t *secret, const uint8_t *basepoint);
