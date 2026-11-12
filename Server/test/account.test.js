import {test} from 'node:test';
import assert from 'node:assert/strict';
import {normalizePhone,passwordHash,passwordMatches,profileFields} from '../src/account-routes.js';
test('Phone normalization, birthday/profile validation and salted passwords',()=>{
 assert.equal(normalizePhone('0901 234 567'),'+84901234567');
 assert.equal(normalizePhone('+84 (901) 234-567'),'+84901234567');
 assert.equal(normalizePhone(''),null);
 assert.throws(()=>normalizePhone(123));
 assert.throws(()=>normalizePhone('abc'));
 assert.throws(()=>profileFields({displayName:'Valid name',dateOfBirth:'2025-02-29'}));
 assert.throws(()=>profileFields({displayName:'Valid name',dateOfBirth:'2999-01-01'}));
 assert.throws(()=>profileFields({displayName:'Valid name',avatarUrl:'http://example.com/a.jpg'}));
 assert.equal(profileFields({displayName:' Valid name ',dateOfBirth:'2004-02-29'}).birth,'2004-02-29');
 const hash=passwordHash('Password123');
 assert.ok(passwordMatches('Password123',hash));
 assert.equal(passwordMatches('Wrong123',hash),false);
 assert.notEqual(hash,passwordHash('Password123'));
 assert.throws(()=>passwordHash('short'));
});
