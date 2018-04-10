(function(){var supportsDirectProtoAccess=function(){var z=function(){}
z.prototype={p:{}}
var y=new z()
if(!(y.__proto__&&y.__proto__.p===z.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var x=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(x))return true}}catch(w){}return false}()
function map(a){a=Object.create(null)
a.x=0
delete a.x
return a}var A=map()
var B=map()
var C=map()
var D=map()
var E=map()
var F=map()
var G=map()
var H=map()
var J=map()
var K=map()
var L=map()
var M=map()
var N=map()
var O=map()
var P=map()
var Q=map()
var R=map()
var S=map()
var T=map()
var U=map()
var V=map()
var W=map()
var X=map()
var Y=map()
var Z=map()
function I(){}init()
function setupProgram(a,b){"use strict"
function generateAccessor(a9,b0,b1){var g=a9.split("-")
var f=g[0]
var e=f.length
var d=f.charCodeAt(e-1)
var c
if(g.length>1)c=true
else c=false
d=d>=60&&d<=64?d-59:d>=123&&d<=126?d-117:d>=37&&d<=43?d-27:0
if(d){var a0=d&3
var a1=d>>2
var a2=f=f.substring(0,e-1)
var a3=f.indexOf(":")
if(a3>0){a2=f.substring(0,a3)
f=f.substring(a3+1)}if(a0){var a4=a0&2?"r":""
var a5=a0&1?"this":"r"
var a6="return "+a5+"."+f
var a7=b1+".prototype.g"+a2+"="
var a8="function("+a4+"){"+a6+"}"
if(c)b0.push(a7+"$reflectable("+a8+");\n")
else b0.push(a7+a8+";\n")}if(a1){var a4=a1&2?"r,v":"v"
var a5=a1&1?"this":"r"
var a6=a5+"."+f+"=v"
var a7=b1+".prototype.s"+a2+"="
var a8="function("+a4+"){"+a6+"}"
if(c)b0.push(a7+"$reflectable("+a8+");\n")
else b0.push(a7+a8+";\n")}}return f}function defineClass(a2,a3){var g=[]
var f="function "+a2+"("
var e=""
var d=""
for(var c=0;c<a3.length;c++){if(c!=0)f+=", "
var a0=generateAccessor(a3[c],g,a2)
d+="'"+a0+"',"
var a1="p_"+a0
f+=a1
e+="this."+a0+" = "+a1+";\n"}if(supportsDirectProtoAccess)e+="this."+"$deferredAction"+"();"
f+=") {\n"+e+"}\n"
f+=a2+".builtin$cls=\""+a2+"\";\n"
f+="$desc=$collectedClasses."+a2+"[1];\n"
f+=a2+".prototype = $desc;\n"
if(typeof defineClass.name!="string")f+=a2+".name=\""+a2+"\";\n"
f+=a2+"."+"$__fields__"+"=["+d+"];\n"
f+=g.join("")
return f}init.createNewIsolate=function(){return new I()}
init.classIdExtractor=function(c){return c.constructor.name}
init.classFieldsExtractor=function(c){var g=c.constructor.$__fields__
if(!g)return[]
var f=[]
f.length=g.length
for(var e=0;e<g.length;e++)f[e]=c[g[e]]
return f}
init.instanceFromClassId=function(c){return new init.allClasses[c]()}
init.initializeEmptyInstance=function(c,d,e){init.allClasses[c].apply(d,e)
return d}
var z=supportsDirectProtoAccess?function(c,d){var g=c.prototype
g.__proto__=d.prototype
g.constructor=c
g["$is"+c.name]=c
return convertToFastObject(g)}:function(){function tmp(){}return function(a0,a1){tmp.prototype=a1.prototype
var g=new tmp()
convertToSlowObject(g)
var f=a0.prototype
var e=Object.keys(f)
for(var d=0;d<e.length;d++){var c=e[d]
g[c]=f[c]}g["$is"+a0.name]=a0
g.constructor=a0
a0.prototype=g
return g}}()
function finishClasses(a4){var g=init.allClasses
a4.combinedConstructorFunction+="return [\n"+a4.constructorsList.join(",\n  ")+"\n]"
var f=new Function("$collectedClasses",a4.combinedConstructorFunction)(a4.collected)
a4.combinedConstructorFunction=null
for(var e=0;e<f.length;e++){var d=f[e]
var c=d.name
var a0=a4.collected[c]
var a1=a0[0]
a0=a0[1]
g[c]=d
a1[c]=d}f=null
var a2=init.finishedClasses
function finishClass(c1){if(a2[c1])return
a2[c1]=true
var a5=a4.pending[c1]
if(a5&&a5.indexOf("+")>0){var a6=a5.split("+")
a5=a6[0]
var a7=a6[1]
finishClass(a7)
var a8=g[a7]
var a9=a8.prototype
var b0=g[c1].prototype
var b1=Object.keys(a9)
for(var b2=0;b2<b1.length;b2++){var b3=b1[b2]
if(!u.call(b0,b3))b0[b3]=a9[b3]}}if(!a5||typeof a5!="string"){var b4=g[c1]
var b5=b4.prototype
b5.constructor=b4
b5.$ise=b4
b5.$deferredAction=function(){}
return}finishClass(a5)
var b6=g[a5]
if(!b6)b6=existingIsolateProperties[a5]
var b4=g[c1]
var b5=z(b4,b6)
if(a9)b5.$deferredAction=mixinDeferredActionHelper(a9,b5)
if(Object.prototype.hasOwnProperty.call(b5,"%")){var b7=b5["%"].split(";")
if(b7[0]){var b8=b7[0].split("|")
for(var b2=0;b2<b8.length;b2++){init.interceptorsByTag[b8[b2]]=b4
init.leafTags[b8[b2]]=true}}if(b7[1]){b8=b7[1].split("|")
if(b7[2]){var b9=b7[2].split("|")
for(var b2=0;b2<b9.length;b2++){var c0=g[b9[b2]]
c0.$nativeSuperclassTag=b8[0]}}for(b2=0;b2<b8.length;b2++){init.interceptorsByTag[b8[b2]]=b4
init.leafTags[b8[b2]]=false}}b5.$deferredAction()}if(b5.$isk)b5.$deferredAction()}var a3=Object.keys(a4.pending)
for(var e=0;e<a3.length;e++)finishClass(a3[e])}function finishAddStubsHelper(){var g=this
while(!g.hasOwnProperty("$deferredAction"))g=g.__proto__
delete g.$deferredAction
var f=Object.keys(g)
for(var e=0;e<f.length;e++){var d=f[e]
var c=d.charCodeAt(0)
var a0
if(d!=="^"&&d!=="$reflectable"&&c!==43&&c!==42&&(a0=g[d])!=null&&a0.constructor===Array&&d!=="<>")addStubs(g,a0,d,false,[])}convertToFastObject(g)
g=g.__proto__
g.$deferredAction()}function mixinDeferredActionHelper(c,d){var g
if(d.hasOwnProperty("$deferredAction"))g=d.$deferredAction
return function foo(){if(!supportsDirectProtoAccess)return
var f=this
while(!f.hasOwnProperty("$deferredAction"))f=f.__proto__
if(g)f.$deferredAction=g
else{delete f.$deferredAction
convertToFastObject(f)}c.$deferredAction()
f.$deferredAction()}}function processClassData(b1,b2,b3){b2=convertToSlowObject(b2)
var g
var f=Object.keys(b2)
var e=false
var d=supportsDirectProtoAccess&&b1!="e"
for(var c=0;c<f.length;c++){var a0=f[c]
var a1=a0.charCodeAt(0)
if(a0==="w"){processStatics(init.statics[b1]=b2.w,b3)
delete b2.w}else if(a1===43){w[g]=a0.substring(1)
var a2=b2[a0]
if(a2>0)b2[g].$reflectable=a2}else if(a1===42){b2[g].$D=b2[a0]
var a3=b2.$methodsWithOptionalArguments
if(!a3)b2.$methodsWithOptionalArguments=a3={}
a3[a0]=g}else{var a4=b2[a0]
if(a0!=="^"&&a4!=null&&a4.constructor===Array&&a0!=="<>")if(d)e=true
else addStubs(b2,a4,a0,false,[])
else g=a0}}if(e)b2.$deferredAction=finishAddStubsHelper
var a5=b2["^"],a6,a7,a8=a5
var a9=a8.split(";")
a8=a9[1]?a9[1].split(","):[]
a7=a9[0]
a6=a7.split(":")
if(a6.length==2){a7=a6[0]
var b0=a6[1]
if(b0)b2.$S=function(b4){return function(){return init.types[b4]}}(b0)}if(a7)b3.pending[b1]=a7
b3.combinedConstructorFunction+=defineClass(b1,a8)
b3.constructorsList.push(b1)
b3.collected[b1]=[m,b2]
i.push(b1)}function processStatics(a3,a4){var g=Object.keys(a3)
for(var f=0;f<g.length;f++){var e=g[f]
if(e==="^")continue
var d=a3[e]
var c=e.charCodeAt(0)
var a0
if(c===43){v[a0]=e.substring(1)
var a1=a3[e]
if(a1>0)a3[a0].$reflectable=a1
if(d&&d.length)init.typeInformation[a0]=d}else if(c===42){m[a0].$D=d
var a2=a3.$methodsWithOptionalArguments
if(!a2)a3.$methodsWithOptionalArguments=a2={}
a2[e]=a0}else if(typeof d==="function"){m[a0=e]=d
h.push(e)
init.globalFunctions[e]=d}else if(d.constructor===Array)addStubs(m,d,e,true,h)
else{a0=e
processClassData(e,d,a4)}}}function addStubs(b6,b7,b8,b9,c0){var g=0,f=b7[g],e
if(typeof f=="string")e=b7[++g]
else{e=f
f=b8}var d=[b6[b8]=b6[f]=e]
e.$stubName=b8
c0.push(b8)
for(g++;g<b7.length;g++){e=b7[g]
if(typeof e!="function")break
if(!b9)e.$stubName=b7[++g]
d.push(e)
if(e.$stubName){b6[e.$stubName]=e
c0.push(e.$stubName)}}for(var c=0;c<d.length;g++,c++)d[c].$callName=b7[g]
var a0=b7[g]
b7=b7.slice(++g)
var a1=b7[0]
var a2=a1>>1
var a3=(a1&1)===1
var a4=a1===3
var a5=a1===1
var a6=b7[1]
var a7=a6>>1
var a8=(a6&1)===1
var a9=a2+a7!=d[0].length
var b0=b7[2]
if(typeof b0=="number")b7[2]=b0+b
var b1=2*a7+a2+3
if(a0){e=tearOff(d,b7,b9,b8,a9)
b6[b8].$getter=e
e.$getterStub=true
if(b9){init.globalFunctions[b8]=e
c0.push(a0)}b6[a0]=e
d.push(e)
e.$stubName=a0
e.$callName=null}var b2=b7.length>b1
if(b2){d[0].$reflectable=1
d[0].$reflectionInfo=b7
for(var c=1;c<d.length;c++){d[c].$reflectable=2
d[c].$reflectionInfo=b7}var b3=b9?init.mangledGlobalNames:init.mangledNames
var b4=b7[b1]
var b5=b4
if(a0)b3[a0]=b5
if(a4)b5+="="
else if(!a5)b5+=":"+(a2+a7)
b3[b8]=b5
d[0].$reflectionName=b5
d[0].$metadataIndex=b1+1
if(a7)b6[b4+"*"]=d[0]}}function tearOffGetter(c,d,e,f){return f?new Function("funcs","reflectionInfo","name","H","c","return function tearOff_"+e+y+++"(x) {"+"if (c === null) c = "+"H.d7"+"("+"this, funcs, reflectionInfo, false, [x], name);"+"return new c(this, funcs[0], x, name);"+"}")(c,d,e,H,null):new Function("funcs","reflectionInfo","name","H","c","return function tearOff_"+e+y+++"() {"+"if (c === null) c = "+"H.d7"+"("+"this, funcs, reflectionInfo, false, [], name);"+"return new c(this, funcs[0], null, name);"+"}")(c,d,e,H,null)}function tearOff(c,d,e,f,a0){var g
return e?function(){if(g===void 0)g=H.d7(this,c,d,true,[],f).prototype
return g}:tearOffGetter(c,d,f,a0)}var y=0
if(!init.libraries)init.libraries=[]
if(!init.mangledNames)init.mangledNames=map()
if(!init.mangledGlobalNames)init.mangledGlobalNames=map()
if(!init.statics)init.statics=map()
if(!init.typeInformation)init.typeInformation=map()
if(!init.globalFunctions)init.globalFunctions=map()
var x=init.libraries
var w=init.mangledNames
var v=init.mangledGlobalNames
var u=Object.prototype.hasOwnProperty
var t=a.length
var s=map()
s.collected=map()
s.pending=map()
s.constructorsList=[]
s.combinedConstructorFunction="function $reflectable(fn){fn.$reflectable=1;return fn};\n"+"var $desc;\n"
for(var r=0;r<t;r++){var q=a[r]
var p=q[0]
var o=q[1]
var n=q[2]
var m=q[3]
var l=q[4]
var k=!!q[5]
var j=l&&l["^"]
if(j instanceof Array)j=j[0]
var i=[]
var h=[]
processStatics(l,s)
x.push([p,o,i,h,n,j,k,m])}finishClasses(s)}I.R=function(){}
var dart=[["","",,H,{"^":"",mW:{"^":"e;a"}}],["","",,J,{"^":"",
j:function(a){return void 0},
cf:function(a,b,c,d){return{i:a,p:b,e:c,x:d}},
cb:function(a){var z,y,x,w,v
z=a[init.dispatchPropertyName]
if(z==null)if($.db==null){H.lM()
z=a[init.dispatchPropertyName]}if(z!=null){y=z.p
if(!1===y)return z.i
if(!0===y)return a
x=Object.getPrototypeOf(a)
if(y===x)return z.i
if(z.e===x)throw H.c(new P.cT("Return interceptor for "+H.b(y(a,z))))}w=a.constructor
v=w==null?null:w[$.$get$cF()]
if(v!=null)return v
v=H.lW(a)
if(v!=null)return v
if(typeof a=="function")return C.F
y=Object.getPrototypeOf(a)
if(y==null)return C.t
if(y===Object.prototype)return C.t
if(typeof w=="function"){Object.defineProperty(w,$.$get$cF(),{value:C.l,enumerable:false,writable:true,configurable:true})
return C.l}return C.l},
k:{"^":"e;",
G:function(a,b){return a===b},
gI:function(a){return H.ax(a)},
j:["fi",function(a){return H.c_(a)}],
cS:["fh",function(a,b){throw H.c(P.e1(a,b.geB(),b.geI(),b.geC(),null))},null,"giC",2,0,null,8],
"%":"CanvasGradient|CanvasPattern|Client|DOMError|DOMImplementation|FileError|MediaError|NavigatorUserMediaError|PositionError|PushMessageData|SQLError|SVGAnimatedEnumeration|SVGAnimatedLength|SVGAnimatedLengthList|SVGAnimatedNumber|SVGAnimatedNumberList|SVGAnimatedString|WebGLRenderingContext|WindowClient"},
ih:{"^":"k;",
j:function(a){return String(a)},
gI:function(a){return a?519018:218159},
$isbI:1},
ij:{"^":"k;",
G:function(a,b){return null==b},
j:function(a){return"null"},
gI:function(a){return 0},
cS:[function(a,b){return this.fh(a,b)},null,"giC",2,0,null,8]},
cG:{"^":"k;",
gI:function(a){return 0},
j:["fk",function(a){return String(a)}],
$isik:1},
iV:{"^":"cG;"},
bD:{"^":"cG;"},
by:{"^":"cG;",
j:function(a){var z=a[$.$get$bO()]
return z==null?this.fk(a):J.C(z)},
$iscC:1,
$S:function(){return{func:1,opt:[,,,,,,,,,,,,,,,,]}}},
bv:{"^":"k;$ti",
eh:function(a,b){if(!!a.immutable$list)throw H.c(new P.u(b))},
b3:function(a,b){if(!!a.fixed$length)throw H.c(new P.u(b))},
C:function(a,b){this.b3(a,"add")
a.push(b)},
ah:function(a,b){var z
this.b3(a,"removeAt")
z=a.length
if(b>=z)throw H.c(P.ba(b,null,null))
return a.splice(b,1)[0]},
A:function(a,b){var z
this.b3(a,"remove")
for(z=0;z<a.length;++z)if(J.J(a[z],b)){a.splice(z,1)
return!0}return!1},
W:function(a,b){var z
this.b3(a,"addAll")
for(z=J.E(b);z.m();)a.push(z.gq())},
K:function(a,b){var z,y
z=a.length
for(y=0;y<z;++y){b.$1(a[y])
if(a.length!==z)throw H.c(new P.a8(a))}},
ag:function(a,b){return new H.b7(a,b,[H.F(a,0),null])},
ib:function(a,b,c){var z,y,x
z=a.length
for(y=!1,x=0;x<z;++x){y=c.$2(y,a[x])
if(a.length!==z)throw H.c(new P.a8(a))}return y},
J:function(a,b){if(b>>>0!==b||b>=a.length)return H.a(a,b)
return a[b]},
gia:function(a){if(a.length>0)return a[0]
throw H.c(H.cE())},
Z:function(a,b,c,d,e){var z,y,x
this.eh(a,"setRange")
P.cP(b,c,a.length,null,null,null)
z=c-b
if(z===0)return
if(e<0)H.B(P.H(e,0,null,"skipCount",null))
if(e+z>d.length)throw H.c(H.dR())
if(e<b)for(y=z-1;y>=0;--y){x=e+y
if(x<0||x>=d.length)return H.a(d,x)
a[b+y]=d[x]}else for(y=0;y<z;++y){x=e+y
if(x<0||x>=d.length)return H.a(d,x)
a[b+y]=d[x]}},
eb:function(a,b){var z,y
z=a.length
for(y=0;y<z;++y){if(b.$1(a[y])===!0)return!0
if(a.length!==z)throw H.c(new P.a8(a))}return!1},
L:function(a,b){var z
for(z=0;z<a.length;++z)if(J.J(a[z],b))return!0
return!1},
gD:function(a){return a.length===0},
gU:function(a){return a.length!==0},
j:function(a){return P.bS(a,"[","]")},
gE:function(a){return new J.bo(a,a.length,0,null)},
gI:function(a){return H.ax(a)},
gi:function(a){return a.length},
si:function(a,b){this.b3(a,"set length")
if(b<0)throw H.c(P.H(b,0,null,"newLength",null))
a.length=b},
h:function(a,b){if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(H.M(a,b))
if(b>=a.length||b<0)throw H.c(H.M(a,b))
return a[b]},
l:function(a,b,c){this.eh(a,"indexed set")
if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(H.M(a,b))
if(b>=a.length||b<0)throw H.c(H.M(a,b))
a[b]=c},
$isT:1,
$asT:I.R,
$ish:1,
$ash:null,
$isi:1,
$asi:null},
mV:{"^":"bv;$ti"},
bo:{"^":"e;a,b,c,d",
gq:function(){return this.d},
m:function(){var z,y,x
z=this.a
y=z.length
if(this.b!==y)throw H.c(H.A(z))
x=this.c
if(x>=y){this.d=null
return!1}this.d=z[x]
this.c=x+1
return!0}},
bw:{"^":"k;",
git:function(a){return a===0?1/a<0:a<0},
e8:function(a){return Math.abs(a)},
d5:function(a){var z
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){z=a<0?Math.ceil(a):Math.floor(a)
return z+0}throw H.c(new P.u(""+a+".toInt()"))},
aB:function(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw H.c(new P.u(""+a+".round()"))},
iQ:function(a,b){var z
if(b>20)throw H.c(P.H(b,0,20,"fractionDigits",null))
z=a.toFixed(b)
if(a===0&&this.git(a))return"-"+z
return z},
j:function(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gI:function(a){return a&0x1FFFFFFF},
v:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a+b},
V:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a-b},
aj:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a/b},
H:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a*b},
c4:function(a,b){if((a|0)===a)if(b>=1||!1)return a/b|0
return this.e2(a,b)},
bF:function(a,b){return(a|0)===a?a/b|0:this.e2(a,b)},
e2:function(a,b){var z=a/b
if(z>=-2147483648&&z<=2147483647)return z|0
if(z>0){if(z!==1/0)return Math.floor(z)}else if(z>-1/0)return Math.ceil(z)
throw H.c(new P.u("Result of truncating division is "+H.b(z)+": "+H.b(a)+" ~/ "+b))},
fa:function(a,b){if(b<0)throw H.c(H.L(b))
return b>31?0:a<<b>>>0},
fb:function(a,b){var z
if(b<0)throw H.c(H.L(b))
if(a>0)z=b>31?0:a>>>b
else{z=b>31?31:b
z=a>>z>>>0}return z},
cz:function(a,b){var z
if(a>0)z=b>31?0:a>>>b
else{z=b>31?31:b
z=a>>z>>>0}return z},
ft:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return(a^b)>>>0},
ak:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a<b},
bX:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a>b},
bV:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a>=b},
$isbi:1},
dT:{"^":"bw;",$isbi:1,$isy:1},
dS:{"^":"bw;",$isbi:1},
bx:{"^":"k;",
cH:function(a,b){if(b<0)throw H.c(H.M(a,b))
if(b>=a.length)H.B(H.M(a,b))
return a.charCodeAt(b)},
aS:function(a,b){if(b>=a.length)throw H.c(H.M(a,b))
return a.charCodeAt(b)},
eA:function(a,b,c){var z,y
if(c>b.length)throw H.c(P.H(c,0,b.length,null,null))
z=a.length
if(c+z>b.length)return
for(y=0;y<z;++y)if(this.aS(b,c+y)!==this.aS(a,y))return
return new H.js(c,b,a)},
v:function(a,b){if(typeof b!=="string")throw H.c(P.co(b,null,null))
return a+b},
i7:function(a,b){var z,y
z=b.length
y=a.length
if(z>y)return!1
return b===this.de(a,y-z)},
iK:function(a,b,c){H.d6(c)
return H.dd(a,b,c)},
fd:function(a,b,c){var z
if(c>a.length)throw H.c(P.H(c,0,a.length,null,null))
if(typeof b==="string"){z=c+b.length
if(z>a.length)return!1
return b===a.substring(c,z)}return J.fG(b,a,c)!=null},
fc:function(a,b){return this.fd(a,b,0)},
am:function(a,b,c){var z
if(typeof b!=="number"||Math.floor(b)!==b)H.B(H.L(b))
if(c==null)c=a.length
if(typeof c!=="number"||Math.floor(c)!==c)H.B(H.L(c))
z=J.a6(b)
if(z.ak(b,0))throw H.c(P.ba(b,null,null))
if(z.bX(b,c))throw H.c(P.ba(b,null,null))
if(J.az(c,a.length))throw H.c(P.ba(c,null,null))
return a.substring(b,c)},
de:function(a,b){return this.am(a,b,null)},
iP:function(a){return a.toLowerCase()},
eS:function(a){var z,y,x,w,v
z=a.trim()
y=z.length
if(y===0)return z
if(this.aS(z,0)===133){x=J.il(z,1)
if(x===y)return""}else x=0
w=y-1
v=this.cH(z,w)===133?J.im(z,w):y
if(x===0&&v===y)return z
return z.substring(x,v)},
H:function(a,b){var z,y
if(typeof b!=="number")return H.l(b)
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw H.c(C.v)
for(z=a,y="";!0;){if((b&1)===1)y=z+y
b=b>>>1
if(b===0)break
z+=z}return y},
hS:function(a,b,c){if(c>a.length)throw H.c(P.H(c,0,a.length,null,null))
return H.m8(a,b,c)},
gU:function(a){return a.length!==0},
j:function(a){return a},
gI:function(a){var z,y,x
for(z=a.length,y=0,x=0;x<z;++x){y=536870911&y+a.charCodeAt(x)
y=536870911&y+((524287&y)<<10)
y^=y>>6}y=536870911&y+((67108863&y)<<3)
y^=y>>11
return 536870911&y+((16383&y)<<15)},
gi:function(a){return a.length},
h:function(a,b){if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(H.M(a,b))
if(b>=a.length||b<0)throw H.c(H.M(a,b))
return a[b]},
$isT:1,
$asT:I.R,
$isp:1,
w:{
dU:function(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
il:function(a,b){var z,y
for(z=a.length;b<z;){y=C.e.aS(a,b)
if(y!==32&&y!==13&&!J.dU(y))break;++b}return b},
im:function(a,b){var z,y
for(;b>0;b=z){z=b-1
y=C.e.cH(a,z)
if(y!==32&&y!==13&&!J.dU(y))break}return b}}}}],["","",,H,{"^":"",
eZ:function(a){if(a<0)H.B(P.H(a,0,null,"count",null))
return a},
cE:function(){return new P.a5("No element")},
ig:function(){return new P.a5("Too many elements")},
dR:function(){return new P.a5("Too few elements")},
i:{"^":"Q;$ti",$asi:null},
aG:{"^":"i;$ti",
gE:function(a){return new H.bU(this,this.gi(this),0,null)},
gD:function(a){return this.gi(this)===0},
d8:function(a,b){return this.fj(0,b)},
ag:function(a,b){return new H.b7(this,b,[H.I(this,"aG",0),null])},
aC:function(a,b){var z,y,x
z=H.q([],[H.I(this,"aG",0)])
C.a.si(z,this.gi(this))
for(y=0;y<this.gi(this);++y){x=this.J(0,y)
if(y>=z.length)return H.a(z,y)
z[y]=x}return z},
aM:function(a){return this.aC(a,!0)}},
cQ:{"^":"aG;a,b,c,$ti",
gfX:function(){var z,y
z=J.a1(this.a)
y=this.c
if(y==null||y>z)return z
return y},
ghA:function(){var z,y
z=J.a1(this.a)
y=this.b
if(y>z)return z
return y},
gi:function(a){var z,y,x
z=J.a1(this.a)
y=this.b
if(y>=z)return 0
x=this.c
if(x==null||x>=z)return z-y
if(typeof x!=="number")return x.V()
return x-y},
J:function(a,b){var z,y
z=this.ghA()
if(typeof b!=="number")return H.l(b)
y=z+b
if(!(b<0)){z=this.gfX()
if(typeof z!=="number")return H.l(z)
z=y>=z}else z=!0
if(z)throw H.c(P.aj(b,this,"index",null,null))
return J.b1(this.a,y)},
iO:function(a,b){var z,y,x
if(b<0)H.B(P.H(b,0,null,"count",null))
z=this.c
y=this.b
x=y+b
if(z==null)return H.ep(this.a,y,x,H.F(this,0))
else{if(z<x)return this
return H.ep(this.a,y,x,H.F(this,0))}},
aC:function(a,b){var z,y,x,w,v,u,t,s,r
z=this.b
y=this.a
x=J.v(y)
w=x.gi(y)
v=this.c
if(v!=null&&v<w)w=v
if(typeof w!=="number")return w.V()
u=w-z
if(u<0)u=0
t=H.q(new Array(u),this.$ti)
for(s=0;s<u;++s){r=x.J(y,z+s)
if(s>=t.length)return H.a(t,s)
t[s]=r
if(x.gi(y)<w)throw H.c(new P.a8(this))}return t},
fC:function(a,b,c,d){var z,y
z=this.b
if(z<0)H.B(P.H(z,0,null,"start",null))
y=this.c
if(y!=null){if(y<0)H.B(P.H(y,0,null,"end",null))
if(z>y)throw H.c(P.H(z,0,y,"start",null))}},
w:{
ep:function(a,b,c,d){var z=new H.cQ(a,b,c,[d])
z.fC(a,b,c,d)
return z}}},
bU:{"^":"e;a,b,c,d",
gq:function(){return this.d},
m:function(){var z,y,x,w
z=this.a
y=J.v(z)
x=y.gi(z)
if(this.b!==x)throw H.c(new P.a8(z))
w=this.c
if(w>=x){this.d=null
return!1}this.d=y.J(z,w);++this.c
return!0}},
bV:{"^":"Q;a,b,$ti",
gE:function(a){return new H.iF(null,J.E(this.a),this.b,this.$ti)},
gi:function(a){return J.a1(this.a)},
gD:function(a){return J.fA(this.a)},
J:function(a,b){return this.b.$1(J.b1(this.a,b))},
$asQ:function(a,b){return[b]},
w:{
bW:function(a,b,c,d){if(!!J.j(a).$isi)return new H.cx(a,b,[c,d])
return new H.bV(a,b,[c,d])}}},
cx:{"^":"bV;a,b,$ti",$isi:1,
$asi:function(a,b){return[b]}},
iF:{"^":"bT;a,b,c,$ti",
m:function(){var z=this.b
if(z.m()){this.a=this.c.$1(z.gq())
return!0}this.a=null
return!1},
gq:function(){return this.a}},
b7:{"^":"aG;a,b,$ti",
gi:function(a){return J.a1(this.a)},
J:function(a,b){return this.b.$1(J.b1(this.a,b))},
$asaG:function(a,b){return[b]},
$asi:function(a,b){return[b]},
$asQ:function(a,b){return[b]}},
cU:{"^":"Q;a,b,$ti",
gE:function(a){return new H.jL(J.E(this.a),this.b,this.$ti)},
ag:function(a,b){return new H.bV(this,b,[H.F(this,0),null])}},
jL:{"^":"bT;a,b,$ti",
m:function(){var z,y
for(z=this.a,y=this.b;z.m();)if(y.$1(z.gq())===!0)return!0
return!1},
gq:function(){return this.a.gq()}},
eq:{"^":"Q;a,b,$ti",
gE:function(a){return new H.jv(J.E(this.a),this.b,this.$ti)},
w:{
ju:function(a,b,c){if(b<0)throw H.c(P.aB(b))
if(!!J.j(a).$isi)return new H.hq(a,b,[c])
return new H.eq(a,b,[c])}}},
hq:{"^":"eq;a,b,$ti",
gi:function(a){var z,y
z=J.a1(this.a)
y=this.b
if(z>y)return y
return z},
$isi:1,
$asi:null},
jv:{"^":"bT;a,b,$ti",
m:function(){if(--this.b>=0)return this.a.m()
this.b=-1
return!1},
gq:function(){if(this.b<0)return
return this.a.gq()}},
ek:{"^":"Q;a,b,$ti",
gE:function(a){return new H.jm(J.E(this.a),this.b,this.$ti)},
w:{
jl:function(a,b,c){if(!!J.j(a).$isi)return new H.hp(a,H.eZ(b),[c])
return new H.ek(a,H.eZ(b),[c])}}},
hp:{"^":"ek;a,b,$ti",
gi:function(a){var z=J.a1(this.a)-this.b
if(z>=0)return z
return 0},
$isi:1,
$asi:null},
jm:{"^":"bT;a,b,$ti",
m:function(){var z,y
for(z=this.a,y=0;y<this.b;++y)z.m()
this.b=0
return z.m()},
gq:function(){return this.a.gq()}},
dN:{"^":"e;$ti",
si:function(a,b){throw H.c(new P.u("Cannot change the length of a fixed-length list"))},
C:function(a,b){throw H.c(new P.u("Cannot add to a fixed-length list"))},
A:function(a,b){throw H.c(new P.u("Cannot remove from a fixed-length list"))},
ah:function(a,b){throw H.c(new P.u("Cannot remove from a fixed-length list"))}},
cR:{"^":"e;hb:a<",
G:function(a,b){if(b==null)return!1
return b instanceof H.cR&&J.J(this.a,b.a)},
gI:function(a){var z,y
z=this._hashCode
if(z!=null)return z
y=J.a0(this.a)
if(typeof y!=="number")return H.l(y)
z=536870911&664597*y
this._hashCode=z
return z},
j:function(a){return'Symbol("'+H.b(this.a)+'")'}}}],["","",,H,{"^":"",
bH:function(a,b){var z=a.b6(b)
if(!init.globalState.d.cy)init.globalState.f.bi()
return z},
fq:function(a,b){var z,y,x,w,v,u
z={}
z.a=b
if(b==null){b=[]
z.a=b
y=b}else y=b
if(!J.j(y).$ish)throw H.c(P.aB("Arguments to main must be a List: "+H.b(y)))
init.globalState=new H.kE(0,0,1,null,null,null,null,null,null,null,null,null,a)
y=init.globalState
x=self.window==null
w=self.Worker
v=x&&!!self.postMessage
y.x=v
v=!v
if(v)w=w!=null&&$.$get$dP()!=null
else w=!0
y.y=w
y.r=x&&v
y.f=new H.k9(P.cK(null,H.bF),0)
x=P.y
y.z=new H.a2(0,null,null,null,null,null,0,[x,H.d_])
y.ch=new H.a2(0,null,null,null,null,null,0,[x,null])
if(y.x===!0){w=new H.kD()
y.Q=w
self.onmessage=function(c,d){return function(e){c(d,e)}}(H.i8,w)
self.dartPrint=self.dartPrint||function(c){return function(d){if(self.console&&self.console.log)self.console.log(d)
else self.postMessage(c(d))}}(H.kF)}if(init.globalState.x===!0)return
y=init.globalState.a++
w=P.a3(null,null,null,x)
v=new H.c1(0,null,!1)
u=new H.d_(y,new H.a2(0,null,null,null,null,null,0,[x,H.c1]),w,init.createNewIsolate(),v,new H.aN(H.ch()),new H.aN(H.ch()),!1,!1,[],P.a3(null,null,null,null),null,null,!1,!0,P.a3(null,null,null,null))
w.C(0,0)
u.dn(0,v)
init.globalState.e=u
init.globalState.d=u
if(H.aK(a,{func:1,args:[,]}))u.b6(new H.m6(z,a))
else if(H.aK(a,{func:1,args:[,,]}))u.b6(new H.m7(z,a))
else u.b6(a)
init.globalState.f.bi()},
ic:function(){var z=init.currentScript
if(z!=null)return String(z.src)
if(init.globalState.x===!0)return H.id()
return},
id:function(){var z,y
z=new Error().stack
if(z==null){z=function(){try{throw new Error()}catch(x){return x.stack}}()
if(z==null)throw H.c(new P.u("No stack trace"))}y=z.match(new RegExp("^ *at [^(]*\\((.*):[0-9]*:[0-9]*\\)$","m"))
if(y!=null)return y[1]
y=z.match(new RegExp("^[^@]*@(.*):[0-9]*$","m"))
if(y!=null)return y[1]
throw H.c(new P.u('Cannot extract URI from "'+z+'"'))},
i8:[function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o,n
z=new H.c4(!0,[]).au(b.data)
y=J.v(z)
switch(y.h(z,"command")){case"start":init.globalState.b=y.h(z,"id")
x=y.h(z,"functionName")
w=x==null?init.globalState.cx:init.globalFunctions[x]()
v=y.h(z,"args")
u=new H.c4(!0,[]).au(y.h(z,"msg"))
t=y.h(z,"isSpawnUri")
s=y.h(z,"startPaused")
r=new H.c4(!0,[]).au(y.h(z,"replyTo"))
y=init.globalState.a++
q=P.y
p=P.a3(null,null,null,q)
o=new H.c1(0,null,!1)
n=new H.d_(y,new H.a2(0,null,null,null,null,null,0,[q,H.c1]),p,init.createNewIsolate(),o,new H.aN(H.ch()),new H.aN(H.ch()),!1,!1,[],P.a3(null,null,null,null),null,null,!1,!0,P.a3(null,null,null,null))
p.C(0,0)
n.dn(0,o)
init.globalState.f.a.aa(new H.bF(n,new H.i9(w,v,u,t,s,r),"worker-start"))
init.globalState.d=n
init.globalState.f.bi()
break
case"spawn-worker":break
case"message":if(y.h(z,"port")!=null)J.b2(y.h(z,"port"),y.h(z,"msg"))
init.globalState.f.bi()
break
case"close":init.globalState.ch.A(0,$.$get$dQ().h(0,a))
a.terminate()
init.globalState.f.bi()
break
case"log":H.i7(y.h(z,"msg"))
break
case"print":if(init.globalState.x===!0){y=init.globalState.Q
q=P.au(["command","print","msg",z])
q=new H.aT(!0,P.bc(null,P.y)).a5(q)
y.toString
self.postMessage(q)}else P.cg(y.h(z,"msg"))
break
case"error":throw H.c(y.h(z,"msg"))}},null,null,4,0,null,20,0],
i7:function(a){var z,y,x,w
if(init.globalState.x===!0){y=init.globalState.Q
x=P.au(["command","log","msg",a])
x=new H.aT(!0,P.bc(null,P.y)).a5(x)
y.toString
self.postMessage(x)}else try{self.console.log(a)}catch(w){H.D(w)
z=H.a_(w)
y=P.bQ(z)
throw H.c(y)}},
ia:function(a,b,c,d,e,f){var z,y,x,w
z=init.globalState.d
y=z.a
$.ec=$.ec+("_"+y)
$.ed=$.ed+("_"+y)
y=z.e
x=init.globalState.d.a
w=z.f
J.b2(f,["spawned",new H.c6(y,x),w,z.r])
x=new H.ib(a,b,c,d,z)
if(e===!0){z.ea(w,w)
init.globalState.f.a.aa(new H.bF(z,x,"start isolate"))}else x.$0()},
ld:function(a){return new H.c4(!0,[]).au(new H.aT(!1,P.bc(null,P.y)).a5(a))},
m6:{"^":"f:2;a,b",
$0:function(){this.b.$1(this.a.a)}},
m7:{"^":"f:2;a,b",
$0:function(){this.b.$2(this.a.a,null)}},
kE:{"^":"e;a,b,c,d,e,f,r,x,y,z,Q,ch,cx",w:{
kF:[function(a){var z=P.au(["command","print","msg",a])
return new H.aT(!0,P.bc(null,P.y)).a5(z)},null,null,2,0,null,9]}},
d_:{"^":"e;a,b,c,iw:d<,hT:e<,f,r,io:x?,bc:y<,hY:z<,Q,ch,cx,cy,db,dx",
ea:function(a,b){if(!this.f.G(0,a))return
if(this.Q.C(0,b)&&!this.y)this.y=!0
this.cA()},
iI:function(a){var z,y,x,w,v,u
if(!this.y)return
z=this.Q
z.A(0,a)
if(z.a===0){for(z=this.z;y=z.length,y!==0;){if(0>=y)return H.a(z,-1)
x=z.pop()
y=init.globalState.f.a
w=y.b
v=y.a
u=v.length
w=(w-1&u-1)>>>0
y.b=w
if(w<0||w>=u)return H.a(v,w)
v[w]=x
if(w===y.c)y.dM();++y.d}this.y=!1}this.cA()},
hF:function(a,b){var z,y,x
if(this.ch==null)this.ch=[]
for(z=J.j(a),y=0;x=this.ch,y<x.length;y+=2)if(z.G(a,x[y])){z=this.ch
x=y+1
if(x>=z.length)return H.a(z,x)
z[x]=b
return}x.push(a)
this.ch.push(b)},
iH:function(a){var z,y,x
if(this.ch==null)return
for(z=J.j(a),y=0;x=this.ch,y<x.length;y+=2)if(z.G(a,x[y])){z=this.ch
x=y+2
z.toString
if(typeof z!=="object"||z===null||!!z.fixed$length)H.B(new P.u("removeRange"))
P.cP(y,x,z.length,null,null,null)
z.splice(y,x-y)
return}},
f9:function(a,b){if(!this.r.G(0,a))return
this.db=b},
ih:function(a,b,c){var z=J.j(b)
if(!z.G(b,0))z=z.G(b,1)&&!this.cy
else z=!0
if(z){J.b2(a,c)
return}z=this.cx
if(z==null){z=P.cK(null,null)
this.cx=z}z.aa(new H.ks(a,c))},
ig:function(a,b){var z
if(!this.r.G(0,a))return
z=J.j(b)
if(!z.G(b,0))z=z.G(b,1)&&!this.cy
else z=!0
if(z){this.cM()
return}z=this.cx
if(z==null){z=P.cK(null,null)
this.cx=z}z.aa(this.gix())},
ii:function(a,b){var z,y,x
z=this.dx
if(z.a===0){if(this.db===!0&&this===init.globalState.e)return
if(self.console&&self.console.error)self.console.error(a,b)
else{P.cg(a)
if(b!=null)P.cg(b)}return}y=new Array(2)
y.fixed$length=Array
y[0]=J.C(a)
y[1]=b==null?null:J.C(b)
for(x=new P.bG(z,z.r,null,null),x.c=z.e;x.m();)J.b2(x.d,y)},
b6:function(a){var z,y,x,w,v,u,t
z=init.globalState.d
init.globalState.d=this
$=this.d
y=null
x=this.cy
this.cy=!0
try{y=a.$0()}catch(u){w=H.D(u)
v=H.a_(u)
this.ii(w,v)
if(this.db===!0){this.cM()
if(this===init.globalState.e)throw u}}finally{this.cy=x
init.globalState.d=z
if(z!=null)$=z.giw()
if(this.cx!=null)for(;t=this.cx,!t.gD(t);)this.cx.eL().$0()}return y},
ic:function(a){var z=J.v(a)
switch(z.h(a,0)){case"pause":this.ea(z.h(a,1),z.h(a,2))
break
case"resume":this.iI(z.h(a,1))
break
case"add-ondone":this.hF(z.h(a,1),z.h(a,2))
break
case"remove-ondone":this.iH(z.h(a,1))
break
case"set-errors-fatal":this.f9(z.h(a,1),z.h(a,2))
break
case"ping":this.ih(z.h(a,1),z.h(a,2),z.h(a,3))
break
case"kill":this.ig(z.h(a,1),z.h(a,2))
break
case"getErrors":this.dx.C(0,z.h(a,1))
break
case"stopErrors":this.dx.A(0,z.h(a,1))
break}},
cO:function(a){return this.b.h(0,a)},
dn:function(a,b){var z=this.b
if(z.N(a))throw H.c(P.bQ("Registry: ports must be registered only once."))
z.l(0,a,b)},
cA:function(){var z=this.b
if(z.gi(z)-this.c.a>0||this.y||!this.x)init.globalState.z.l(0,this.a,this)
else this.cM()},
cM:[function(){var z,y,x,w,v
z=this.cx
if(z!=null)z.a8(0)
for(z=this.b,y=z.gd7(z),y=y.gE(y);y.m();)y.gq().fQ()
z.a8(0)
this.c.a8(0)
init.globalState.z.A(0,this.a)
this.dx.a8(0)
if(this.ch!=null){for(x=0;z=this.ch,y=z.length,x<y;x+=2){w=z[x]
v=x+1
if(v>=y)return H.a(z,v)
J.b2(w,z[v])}this.ch=null}},"$0","gix",0,0,1]},
ks:{"^":"f:1;a,b",
$0:[function(){J.b2(this.a,this.b)},null,null,0,0,null,"call"]},
k9:{"^":"e;a,b",
hZ:function(){var z=this.a
if(z.b===z.c)return
return z.eL()},
eN:function(){var z,y,x
z=this.hZ()
if(z==null){if(init.globalState.e!=null)if(init.globalState.z.N(init.globalState.e.a))if(init.globalState.r===!0){y=init.globalState.e.b
y=y.gD(y)}else y=!1
else y=!1
else y=!1
if(y)H.B(P.bQ("Program exited with open ReceivePorts."))
y=init.globalState
if(y.x===!0){x=y.z
x=x.gD(x)&&y.f.b===0}else x=!1
if(x){y=y.Q
x=P.au(["command","close"])
x=new H.aT(!0,new P.eU(0,null,null,null,null,null,0,[null,P.y])).a5(x)
y.toString
self.postMessage(x)}return!1}z.iF()
return!0},
dZ:function(){if(self.window!=null)new H.ka(this).$0()
else for(;this.eN(););},
bi:function(){var z,y,x,w,v
if(init.globalState.x!==!0)this.dZ()
else try{this.dZ()}catch(x){z=H.D(x)
y=H.a_(x)
w=init.globalState.Q
v=P.au(["command","error","msg",H.b(z)+"\n"+H.b(y)])
v=new H.aT(!0,P.bc(null,P.y)).a5(v)
w.toString
self.postMessage(v)}}},
ka:{"^":"f:1;a",
$0:function(){if(!this.a.eN())return
P.jA(C.o,this)}},
bF:{"^":"e;a,b,c",
iF:function(){var z=this.a
if(z.gbc()){z.ghY().push(this)
return}z.b6(this.b)}},
kD:{"^":"e;"},
i9:{"^":"f:2;a,b,c,d,e,f",
$0:function(){H.ia(this.a,this.b,this.c,this.d,this.e,this.f)}},
ib:{"^":"f:1;a,b,c,d,e",
$0:function(){var z,y
z=this.e
z.sio(!0)
if(this.d!==!0)this.a.$1(this.c)
else{y=this.a
if(H.aK(y,{func:1,args:[,,]}))y.$2(this.b,this.c)
else if(H.aK(y,{func:1,args:[,]}))y.$1(this.b)
else y.$0()}z.cA()}},
eJ:{"^":"e;"},
c6:{"^":"eJ;b,a",
bZ:function(a,b){var z,y,x
z=init.globalState.z.h(0,this.a)
if(z==null)return
y=this.b
if(y.gdR())return
x=H.ld(b)
if(z.ghT()===y){z.ic(x)
return}init.globalState.f.a.aa(new H.bF(z,new H.kN(this,x),"receive"))},
G:function(a,b){if(b==null)return!1
return b instanceof H.c6&&J.J(this.b,b.b)},
gI:function(a){return this.b.gcm()}},
kN:{"^":"f:2;a,b",
$0:function(){var z=this.a.b
if(!z.gdR())z.fJ(this.b)}},
d0:{"^":"eJ;b,c,a",
bZ:function(a,b){var z,y,x
z=P.au(["command","message","port",this,"msg",b])
y=new H.aT(!0,P.bc(null,P.y)).a5(z)
if(init.globalState.x===!0){init.globalState.Q.toString
self.postMessage(y)}else{x=init.globalState.ch.h(0,this.b)
if(x!=null)x.postMessage(y)}},
G:function(a,b){if(b==null)return!1
return b instanceof H.d0&&J.J(this.b,b.b)&&J.J(this.a,b.a)&&J.J(this.c,b.c)},
gI:function(a){var z,y,x
z=J.dh(this.b,16)
y=J.dh(this.a,8)
x=this.c
if(typeof x!=="number")return H.l(x)
return(z^y^x)>>>0}},
c1:{"^":"e;cm:a<,b,dR:c<",
fQ:function(){this.c=!0
this.b=null},
fJ:function(a){if(this.c)return
this.b.$1(a)},
$isjb:1},
jw:{"^":"e;a,b,c",
aJ:function(){if(self.setTimeout!=null){if(this.b)throw H.c(new P.u("Timer in event loop cannot be canceled."))
var z=this.c
if(z==null)return;--init.globalState.f.b
self.clearTimeout(z)
this.c=null}else throw H.c(new P.u("Canceling a timer."))},
fD:function(a,b){var z,y
if(a===0)z=self.setTimeout==null||init.globalState.x===!0
else z=!1
if(z){this.c=1
z=init.globalState.f
y=init.globalState.d
z.a.aa(new H.bF(y,new H.jy(this,b),"timer"))
this.b=!0}else if(self.setTimeout!=null){++init.globalState.f.b
this.c=self.setTimeout(H.aY(new H.jz(this,b),0),a)}else throw H.c(new P.u("Timer greater than 0."))},
w:{
jx:function(a,b){var z=new H.jw(!0,!1,null)
z.fD(a,b)
return z}}},
jy:{"^":"f:1;a,b",
$0:function(){this.a.c=null
this.b.$0()}},
jz:{"^":"f:1;a,b",
$0:[function(){this.a.c=null;--init.globalState.f.b
this.b.$0()},null,null,0,0,null,"call"]},
aN:{"^":"e;cm:a<",
gI:function(a){var z,y,x
z=this.a
y=J.a6(z)
x=y.fb(z,0)
y=y.c4(z,4294967296)
if(typeof y!=="number")return H.l(y)
z=x^y
z=(~z>>>0)+(z<<15>>>0)&4294967295
z=((z^z>>>12)>>>0)*5&4294967295
z=((z^z>>>4)>>>0)*2057&4294967295
return(z^z>>>16)>>>0},
G:function(a,b){var z,y
if(b==null)return!1
if(b===this)return!0
if(b instanceof H.aN){z=this.a
y=b.a
return z==null?y==null:z===y}return!1}},
aT:{"^":"e;a,b",
a5:[function(a){var z,y,x,w,v
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
z=this.b
y=z.h(0,a)
if(y!=null)return["ref",y]
z.l(0,a,z.gi(z))
z=J.j(a)
if(!!z.$isdX)return["buffer",a]
if(!!z.$isbZ)return["typed",a]
if(!!z.$isT)return this.f4(a)
if(!!z.$isi6){x=this.gf1()
w=a.gM()
w=H.bW(w,x,H.I(w,"Q",0),null)
w=P.av(w,!0,H.I(w,"Q",0))
z=z.gd7(a)
z=H.bW(z,x,H.I(z,"Q",0),null)
return["map",w,P.av(z,!0,H.I(z,"Q",0))]}if(!!z.$isik)return this.f5(a)
if(!!z.$isk)this.eT(a)
if(!!z.$isjb)this.bo(a,"RawReceivePorts can't be transmitted:")
if(!!z.$isc6)return this.f6(a)
if(!!z.$isd0)return this.f7(a)
if(!!z.$isf){v=a.$static_name
if(v==null)this.bo(a,"Closures can't be transmitted:")
return["function",v]}if(!!z.$isaN)return["capability",a.a]
if(!(a instanceof P.e))this.eT(a)
return["dart",init.classIdExtractor(a),this.f3(init.classFieldsExtractor(a))]},"$1","gf1",2,0,0,10],
bo:function(a,b){throw H.c(new P.u((b==null?"Can't transmit:":b)+" "+H.b(a)))},
eT:function(a){return this.bo(a,null)},
f4:function(a){var z=this.f2(a)
if(!!a.fixed$length)return["fixed",z]
if(!a.fixed$length)return["extendable",z]
if(!a.immutable$list)return["mutable",z]
if(a.constructor===Array)return["const",z]
this.bo(a,"Can't serialize indexable: ")},
f2:function(a){var z,y,x
z=[]
C.a.si(z,a.length)
for(y=0;y<a.length;++y){x=this.a5(a[y])
if(y>=z.length)return H.a(z,y)
z[y]=x}return z},
f3:function(a){var z
for(z=0;z<a.length;++z)C.a.l(a,z,this.a5(a[z]))
return a},
f5:function(a){var z,y,x,w
if(!!a.constructor&&a.constructor!==Object)this.bo(a,"Only plain JS Objects are supported:")
z=Object.keys(a)
y=[]
C.a.si(y,z.length)
for(x=0;x<z.length;++x){w=this.a5(a[z[x]])
if(x>=y.length)return H.a(y,x)
y[x]=w}return["js-object",z,y]},
f7:function(a){if(this.a)return["sendport",a.b,a.a,a.c]
return["raw sendport",a]},
f6:function(a){if(this.a)return["sendport",init.globalState.b,a.a,a.b.gcm()]
return["raw sendport",a]}},
c4:{"^":"e;a,b",
au:[function(a){var z,y,x,w,v,u
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
if(typeof a!=="object"||a===null||a.constructor!==Array)throw H.c(P.aB("Bad serialized message: "+H.b(a)))
switch(C.a.gia(a)){case"ref":if(1>=a.length)return H.a(a,1)
z=a[1]
y=this.b
if(z>>>0!==z||z>=y.length)return H.a(y,z)
return y[z]
case"buffer":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return x
case"typed":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return x
case"fixed":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
y=H.q(this.b5(x),[null])
y.fixed$length=Array
return y
case"extendable":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return H.q(this.b5(x),[null])
case"mutable":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return this.b5(x)
case"const":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
y=H.q(this.b5(x),[null])
y.fixed$length=Array
return y
case"map":return this.i1(a)
case"sendport":return this.i2(a)
case"raw sendport":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return x
case"js-object":return this.i0(a)
case"function":if(1>=a.length)return H.a(a,1)
x=init.globalFunctions[a[1]]()
this.b.push(x)
return x
case"capability":if(1>=a.length)return H.a(a,1)
return new H.aN(a[1])
case"dart":y=a.length
if(1>=y)return H.a(a,1)
w=a[1]
if(2>=y)return H.a(a,2)
v=a[2]
u=init.instanceFromClassId(w)
this.b.push(u)
this.b5(v)
return init.initializeEmptyInstance(w,u,v)
default:throw H.c("couldn't deserialize: "+H.b(a))}},"$1","gi_",2,0,0,10],
b5:function(a){var z,y,x
z=J.v(a)
y=0
while(!0){x=z.gi(a)
if(typeof x!=="number")return H.l(x)
if(!(y<x))break
z.l(a,y,this.au(z.h(a,y)));++y}return a},
i1:function(a){var z,y,x,w,v,u
z=a.length
if(1>=z)return H.a(a,1)
y=a[1]
if(2>=z)return H.a(a,2)
x=a[2]
w=P.bA()
this.b.push(w)
y=J.dp(y,this.gi_()).aM(0)
for(z=J.v(y),v=J.v(x),u=0;u<z.gi(y);++u)w.l(0,z.h(y,u),this.au(v.h(x,u)))
return w},
i2:function(a){var z,y,x,w,v,u,t
z=a.length
if(1>=z)return H.a(a,1)
y=a[1]
if(2>=z)return H.a(a,2)
x=a[2]
if(3>=z)return H.a(a,3)
w=a[3]
if(J.J(y,init.globalState.b)){v=init.globalState.z.h(0,x)
if(v==null)return
u=v.cO(w)
if(u==null)return
t=new H.c6(u,x)}else t=new H.d0(y,w,x)
this.b.push(t)
return t},
i0:function(a){var z,y,x,w,v,u,t
z=a.length
if(1>=z)return H.a(a,1)
y=a[1]
if(2>=z)return H.a(a,2)
x=a[2]
w={}
this.b.push(w)
z=J.v(y)
v=J.v(x)
u=0
while(!0){t=z.gi(y)
if(typeof t!=="number")return H.l(t)
if(!(u<t))break
w[z.h(y,u)]=this.au(v.h(x,u));++u}return w}}}],["","",,H,{"^":"",
dA:function(){throw H.c(new P.u("Cannot modify unmodifiable Map"))},
lF:function(a){return init.types[a]},
fj:function(a,b){var z
if(b!=null){z=b.x
if(z!=null)return z}return!!J.j(a).$isZ},
b:function(a){var z
if(typeof a==="string")return a
if(typeof a==="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
z=J.C(a)
if(typeof z!=="string")throw H.c(H.L(a))
return z},
ax:function(a){var z=a.$identityHash
if(z==null){z=Math.random()*0x3fffffff|0
a.$identityHash=z}return z},
ea:function(a,b){if(b==null)throw H.c(new P.bR(a,null,null))
return b.$1(a)},
ee:function(a,b,c){var z,y
z=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(z==null)return H.ea(a,c)
if(3>=z.length)return H.a(z,3)
y=z[3]
if(y!=null)return parseInt(a,10)
if(z[2]!=null)return parseInt(a,16)
return H.ea(a,c)},
e9:function(a,b){return b.$1(a)},
j5:function(a,b){var z,y
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return H.e9(a,b)
z=parseFloat(a)
if(isNaN(z)){y=C.e.eS(a)
if(y==="NaN"||y==="+NaN"||y==="-NaN")return z
return H.e9(a,b)}return z},
c0:function(a){var z,y,x,w,v,u,t,s
z=J.j(a)
y=z.constructor
if(typeof y=="function"){x=y.name
w=typeof x==="string"?x:null}else w=null
if(w==null||z===C.x||!!J.j(a).$isbD){v=C.q(a)
if(v==="Object"){u=a.constructor
if(typeof u=="function"){t=String(u).match(/^\s*function\s*([\w$]*)\s*\(/)
s=t==null?null:t[1]
if(typeof s==="string"&&/^\w+$/.test(s))w=s}if(w==null)w=v}else w=v}w=w
if(w.length>1&&C.e.aS(w,0)===36)w=C.e.de(w,1)
return function(b,c){return b.replace(/[^<,> ]+/g,function(d){return c[d]||d})}(w+H.fk(H.cc(a),0,null),init.mangledGlobalNames)},
c_:function(a){return"Instance of '"+H.c0(a)+"'"},
a4:function(a){var z
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){z=a-65536
return String.fromCharCode((55296|C.f.cz(z,10))>>>0,56320|z&1023)}throw H.c(P.H(a,0,1114111,null,null))},
Y:function(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
j4:function(a){return a.b?H.Y(a).getUTCFullYear()+0:H.Y(a).getFullYear()+0},
j2:function(a){return a.b?H.Y(a).getUTCMonth()+1:H.Y(a).getMonth()+1},
iZ:function(a){return a.b?H.Y(a).getUTCDate()+0:H.Y(a).getDate()+0},
j_:function(a){return a.b?H.Y(a).getUTCHours()+0:H.Y(a).getHours()+0},
j1:function(a){return a.b?H.Y(a).getUTCMinutes()+0:H.Y(a).getMinutes()+0},
j3:function(a){return a.b?H.Y(a).getUTCSeconds()+0:H.Y(a).getSeconds()+0},
j0:function(a){return a.b?H.Y(a).getUTCMilliseconds()+0:H.Y(a).getMilliseconds()+0},
cO:function(a,b){if(a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string")throw H.c(H.L(a))
return a[b]},
ef:function(a,b,c){if(a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string")throw H.c(H.L(a))
a[b]=c},
eb:function(a,b,c){var z,y,x
z={}
z.a=0
y=[]
x=[]
z.a=b.length
C.a.W(y,b)
z.b=""
if(c!=null&&!c.gD(c))c.K(0,new H.iY(z,y,x))
return J.fH(a,new H.ii(C.L,""+"$"+z.a+z.b,0,y,x,null))},
iX:function(a,b){var z,y
z=b instanceof Array?b:P.av(b,!0,null)
y=z.length
if(y===0){if(!!a.$0)return a.$0()}else if(y===1){if(!!a.$1)return a.$1(z[0])}else if(y===2){if(!!a.$2)return a.$2(z[0],z[1])}else if(y===3){if(!!a.$3)return a.$3(z[0],z[1],z[2])}else if(y===4){if(!!a.$4)return a.$4(z[0],z[1],z[2],z[3])}else if(y===5)if(!!a.$5)return a.$5(z[0],z[1],z[2],z[3],z[4])
return H.iW(a,z)},
iW:function(a,b){var z,y,x,w,v,u
z=b.length
y=a[""+"$"+z]
if(y==null){y=J.j(a)["call*"]
if(y==null)return H.eb(a,b,null)
x=H.eh(y)
w=x.d
v=w+x.e
if(x.f||w>z||v<z)return H.eb(a,b,null)
b=P.av(b,!0,null)
for(u=z;u<v;++u)C.a.C(b,init.metadata[x.hX(0,u)])}return y.apply(a,b)},
l:function(a){throw H.c(H.L(a))},
a:function(a,b){if(a==null)J.a1(a)
throw H.c(H.M(a,b))},
M:function(a,b){var z,y
if(typeof b!=="number"||Math.floor(b)!==b)return new P.as(!0,b,"index",null)
z=J.a1(a)
if(!(b<0)){if(typeof z!=="number")return H.l(z)
y=b>=z}else y=!0
if(y)return P.aj(b,a,"index",null,z)
return P.ba(b,"index",null)},
L:function(a){return new P.as(!0,a,null,null)},
bJ:function(a){if(typeof a!=="number")throw H.c(H.L(a))
return a},
d6:function(a){if(typeof a!=="string")throw H.c(H.L(a))
return a},
c:function(a){var z
if(a==null)a=new P.e5()
z=new Error()
z.dartException=a
if("defineProperty" in Object){Object.defineProperty(z,"message",{get:H.fr})
z.name=""}else z.toString=H.fr
return z},
fr:[function(){return J.C(this.dartException)},null,null,0,0,null],
B:function(a){throw H.c(a)},
A:function(a){throw H.c(new P.a8(a))},
D:function(a){var z,y,x,w,v,u,t,s,r,q,p,o,n,m,l
z=new H.ma(a)
if(a==null)return
if(typeof a!=="object")return a
if("dartException" in a)return z.$1(a.dartException)
else if(!("message" in a))return a
y=a.message
if("number" in a&&typeof a.number=="number"){x=a.number
w=x&65535
if((C.f.cz(x,16)&8191)===10)switch(w){case 438:return z.$1(H.cH(H.b(y)+" (Error "+w+")",null))
case 445:case 5007:v=H.b(y)+" (Error "+w+")"
return z.$1(new H.e4(v,null))}}if(a instanceof TypeError){u=$.$get$ew()
t=$.$get$ex()
s=$.$get$ey()
r=$.$get$ez()
q=$.$get$eD()
p=$.$get$eE()
o=$.$get$eB()
$.$get$eA()
n=$.$get$eG()
m=$.$get$eF()
l=u.a9(y)
if(l!=null)return z.$1(H.cH(y,l))
else{l=t.a9(y)
if(l!=null){l.method="call"
return z.$1(H.cH(y,l))}else{l=s.a9(y)
if(l==null){l=r.a9(y)
if(l==null){l=q.a9(y)
if(l==null){l=p.a9(y)
if(l==null){l=o.a9(y)
if(l==null){l=r.a9(y)
if(l==null){l=n.a9(y)
if(l==null){l=m.a9(y)
v=l!=null}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0
if(v)return z.$1(new H.e4(y,l==null?null:l.method))}}return z.$1(new H.jK(typeof y==="string"?y:""))}if(a instanceof RangeError){if(typeof y==="string"&&y.indexOf("call stack")!==-1)return new P.em()
y=function(b){try{return String(b)}catch(k){}return null}(a)
return z.$1(new P.as(!1,null,null,typeof y==="string"?y.replace(/^RangeError:\s*/,""):y))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof y==="string"&&y==="too much recursion")return new P.em()
return a},
a_:function(a){var z
if(a==null)return new H.eV(a,null)
z=a.$cachedTrace
if(z!=null)return z
return a.$cachedTrace=new H.eV(a,null)},
m3:function(a){if(a==null||typeof a!='object')return J.a0(a)
else return H.ax(a)},
lE:function(a,b){var z,y,x,w
z=a.length
for(y=0;y<z;y=w){x=y+1
w=x+1
b.l(0,a[y],a[x])}return b},
lO:[function(a,b,c,d,e,f,g){switch(c){case 0:return H.bH(b,new H.lP(a))
case 1:return H.bH(b,new H.lQ(a,d))
case 2:return H.bH(b,new H.lR(a,d,e))
case 3:return H.bH(b,new H.lS(a,d,e,f))
case 4:return H.bH(b,new H.lT(a,d,e,f,g))}throw H.c(P.bQ("Unsupported number of arguments for wrapped closure"))},null,null,14,0,null,33,22,32,16,17,18,21],
aY:function(a,b){var z
if(a==null)return
z=a.$identity
if(!!z)return z
z=function(c,d,e,f){return function(g,h,i,j){return f(c,e,d,g,h,i,j)}}(a,b,init.globalState.d,H.lO)
a.$identity=z
return z},
h5:function(a,b,c,d,e,f){var z,y,x,w,v,u,t,s,r,q,p,o,n,m
z=b[0]
y=z.$callName
if(!!J.j(c).$ish){z.$reflectionInfo=c
x=H.eh(z).r}else x=c
w=d?Object.create(new H.jn().constructor.prototype):Object.create(new H.cs(null,null,null,null).constructor.prototype)
w.$initialize=w.constructor
if(d)v=function(){this.$initialize()}
else{u=$.ai
$.ai=J.d(u,1)
v=new Function("a,b,c,d"+u,"this.$initialize(a,b,c,d"+u+")")}w.constructor=v
v.prototype=w
if(!d){t=e.length==1&&!0
s=H.dy(a,z,t)
s.$reflectionInfo=c}else{w.$static_name=f
s=z
t=!1}if(typeof x=="number")r=function(g,h){return function(){return g(h)}}(H.lF,x)
else if(typeof x=="function")if(d)r=x
else{q=t?H.dw:H.ct
r=function(g,h){return function(){return g.apply({$receiver:h(this)},arguments)}}(x,q)}else throw H.c("Error in reflectionInfo.")
w.$S=r
w[y]=s
for(u=b.length,p=1;p<u;++p){o=b[p]
n=o.$callName
if(n!=null){m=d?o:H.dy(a,o,t)
w[n]=m}}w["call*"]=s
w.$R=z.$R
w.$D=z.$D
return v},
h2:function(a,b,c,d){var z=H.ct
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,z)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,z)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,z)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,z)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,z)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,z)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,z)}},
dy:function(a,b,c){var z,y,x,w,v,u,t
if(c)return H.h4(a,b)
z=b.$stubName
y=b.length
x=a[z]
w=b==null?x==null:b===x
v=!w||y>=27
if(v)return H.h2(y,!w,z,b)
if(y===0){w=$.ai
$.ai=J.d(w,1)
u="self"+H.b(w)
w="return function(){var "+u+" = this."
v=$.b3
if(v==null){v=H.bN("self")
$.b3=v}return new Function(w+H.b(v)+";return "+u+"."+H.b(z)+"();}")()}t="abcdefghijklmnopqrstuvwxyz".split("").splice(0,y).join(",")
w=$.ai
$.ai=J.d(w,1)
t+=H.b(w)
w="return function("+t+"){return this."
v=$.b3
if(v==null){v=H.bN("self")
$.b3=v}return new Function(w+H.b(v)+"."+H.b(z)+"("+t+");}")()},
h3:function(a,b,c,d){var z,y
z=H.ct
y=H.dw
switch(b?-1:a){case 0:throw H.c(new H.jf("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,z,y)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,z,y)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,z,y)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,z,y)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,z,y)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,z,y)
default:return function(e,f,g,h){return function(){h=[g(this)]
Array.prototype.push.apply(h,arguments)
return e.apply(f(this),h)}}(d,z,y)}},
h4:function(a,b){var z,y,x,w,v,u,t,s
z=H.h0()
y=$.dv
if(y==null){y=H.bN("receiver")
$.dv=y}x=b.$stubName
w=b.length
v=a[x]
u=b==null?v==null:b===v
t=!u||w>=28
if(t)return H.h3(w,!u,x,b)
if(w===1){y="return function(){return this."+H.b(z)+"."+H.b(x)+"(this."+H.b(y)+");"
u=$.ai
$.ai=J.d(u,1)
return new Function(y+H.b(u)+"}")()}s="abcdefghijklmnopqrstuvwxyz".split("").splice(0,w-1).join(",")
y="return function("+s+"){return this."+H.b(z)+"."+H.b(x)+"(this."+H.b(y)+", "+s+");"
u=$.ai
$.ai=J.d(u,1)
return new Function(y+H.b(u)+"}")()},
d7:function(a,b,c,d,e,f){var z
b.fixed$length=Array
if(!!J.j(c).$ish){c.fixed$length=Array
z=c}else z=c
return H.h5(a,b,z,!!d,e,f)},
m2:function(a){if(typeof a==="number"||a==null)return a
throw H.c(H.dx(H.c0(a),"num"))},
m5:function(a,b){var z=J.v(b)
throw H.c(H.dx(H.c0(a),z.am(b,3,z.gi(b))))},
cd:function(a,b){var z
if(a!=null)z=(typeof a==="object"||typeof a==="function")&&J.j(a)[b]
else z=!0
if(z)return a
H.m5(a,b)},
lC:function(a){var z=J.j(a)
return"$S" in z?z.$S():null},
aK:function(a,b){var z
if(a==null)return!1
z=H.lC(a)
return z==null?!1:H.fi(z,b)},
m9:function(a){throw H.c(new P.hf(a))},
ch:function(){return(Math.random()*0x100000000>>>0)+(Math.random()*0x100000000>>>0)*4294967296},
d9:function(a){return init.getIsolateTag(a)},
q:function(a,b){a.$ti=b
return a},
cc:function(a){if(a==null)return
return a.$ti},
fh:function(a,b){return H.de(a["$as"+H.b(b)],H.cc(a))},
I:function(a,b,c){var z=H.fh(a,b)
return z==null?null:z[c]},
F:function(a,b){var z=H.cc(a)
return z==null?null:z[b]},
b_:function(a,b){var z
if(a==null)return"dynamic"
if(typeof a==="object"&&a!==null&&a.constructor===Array)return a[0].builtin$cls+H.fk(a,1,b)
if(typeof a=="function")return a.builtin$cls
if(typeof a==="number"&&Math.floor(a)===a)return H.b(a)
if(typeof a.func!="undefined"){z=a.typedef
if(z!=null)return H.b_(z,b)
return H.lg(a,b)}return"unknown-reified-type"},
lg:function(a,b){var z,y,x,w,v,u,t,s,r,q,p
z=!!a.v?"void":H.b_(a.ret,b)
if("args" in a){y=a.args
for(x=y.length,w="",v="",u=0;u<x;++u,v=", "){t=y[u]
w=w+v+H.b_(t,b)}}else{w=""
v=""}if("opt" in a){s=a.opt
w+=v+"["
for(x=s.length,v="",u=0;u<x;++u,v=", "){t=s[u]
w=w+v+H.b_(t,b)}w+="]"}if("named" in a){r=a.named
w+=v+"{"
for(x=H.lD(r),q=x.length,v="",u=0;u<q;++u,v=", "){p=x[u]
w=w+v+H.b_(r[p],b)+(" "+H.b(p))}w+="}"}return"("+w+") => "+z},
fk:function(a,b,c){var z,y,x,w,v,u
if(a==null)return""
z=new P.aH("")
for(y=b,x=!0,w=!0,v="";y<a.length;++y){if(x)x=!1
else z.k=v+", "
u=a[y]
if(u!=null)w=!1
v=z.k+=H.b_(u,c)}return w?"":"<"+z.j(0)+">"},
de:function(a,b){if(a==null)return b
a=a.apply(null,b)
if(a==null)return
if(typeof a==="object"&&a!==null&&a.constructor===Array)return a
if(typeof a=="function")return a.apply(null,b)
return b},
bK:function(a,b,c,d){var z,y
if(a==null)return!1
z=H.cc(a)
y=J.j(a)
if(y[b]==null)return!1
return H.fe(H.de(y[d],z),c)},
fe:function(a,b){var z,y
if(a==null||b==null)return!0
z=a.length
for(y=0;y<z;++y)if(!H.a7(a[y],b[y]))return!1
return!0},
bg:function(a,b,c){return a.apply(b,H.fh(b,c))},
a7:function(a,b){var z,y,x,w,v,u
if(a===b)return!0
if(a==null||b==null)return!0
if(a.builtin$cls==="b8")return!0
if('func' in b)return H.fi(a,b)
if('func' in a)return b.builtin$cls==="cC"||b.builtin$cls==="e"
z=typeof a==="object"&&a!==null&&a.constructor===Array
y=z?a[0]:a
x=typeof b==="object"&&b!==null&&b.constructor===Array
w=x?b[0]:b
if(w!==y){v=H.b_(w,null)
if(!('$is'+v in y.prototype))return!1
u=y.prototype["$as"+v]}else u=null
if(!z&&u==null||!x)return!0
z=z?a.slice(1):null
x=b.slice(1)
return H.fe(H.de(u,z),x)},
fd:function(a,b,c){var z,y,x,w,v
z=b==null
if(z&&a==null)return!0
if(z)return c
if(a==null)return!1
y=a.length
x=b.length
if(c){if(y<x)return!1}else if(y!==x)return!1
for(w=0;w<x;++w){z=a[w]
v=b[w]
if(!(H.a7(z,v)||H.a7(v,z)))return!1}return!0},
lr:function(a,b){var z,y,x,w,v,u
if(b==null)return!0
if(a==null)return!1
z=Object.getOwnPropertyNames(b)
z.fixed$length=Array
y=z
for(z=y.length,x=0;x<z;++x){w=y[x]
if(!Object.hasOwnProperty.call(a,w))return!1
v=b[w]
u=a[w]
if(!(H.a7(v,u)||H.a7(u,v)))return!1}return!0},
fi:function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o,n,m,l
if(!('func' in a))return!1
if("v" in a){if(!("v" in b)&&"ret" in b)return!1}else if(!("v" in b)){z=a.ret
y=b.ret
if(!(H.a7(z,y)||H.a7(y,z)))return!1}x=a.args
w=b.args
v=a.opt
u=b.opt
t=x!=null?x.length:0
s=w!=null?w.length:0
r=v!=null?v.length:0
q=u!=null?u.length:0
if(t>s)return!1
if(t+r<s+q)return!1
if(t===s){if(!H.fd(x,w,!1))return!1
if(!H.fd(v,u,!0))return!1}else{for(p=0;p<t;++p){o=x[p]
n=w[p]
if(!(H.a7(o,n)||H.a7(n,o)))return!1}for(m=p,l=0;m<s;++l,++m){o=v[l]
n=w[m]
if(!(H.a7(o,n)||H.a7(n,o)))return!1}for(m=0;m<q;++l,++m){o=v[l]
n=u[m]
if(!(H.a7(o,n)||H.a7(n,o)))return!1}}return H.lr(a.named,b.named)},
oi:function(a){var z=$.da
return"Instance of "+(z==null?"<Unknown>":z.$1(a))},
oe:function(a){return H.ax(a)},
od:function(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
lW:function(a){var z,y,x,w,v,u
z=$.da.$1(a)
y=$.c9[z]
if(y!=null){Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}x=$.ce[z]
if(x!=null)return x
w=init.interceptorsByTag[z]
if(w==null){z=$.fc.$2(a,z)
if(z!=null){y=$.c9[z]
if(y!=null){Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}x=$.ce[z]
if(x!=null)return x
w=init.interceptorsByTag[z]}}if(w==null)return
x=w.prototype
v=z[0]
if(v==="!"){y=H.dc(x)
$.c9[z]=y
Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}if(v==="~"){$.ce[z]=x
return x}if(v==="-"){u=H.dc(x)
Object.defineProperty(Object.getPrototypeOf(a),init.dispatchPropertyName,{value:u,enumerable:false,writable:true,configurable:true})
return u.i}if(v==="+")return H.fn(a,x)
if(v==="*")throw H.c(new P.cT(z))
if(init.leafTags[z]===true){u=H.dc(x)
Object.defineProperty(Object.getPrototypeOf(a),init.dispatchPropertyName,{value:u,enumerable:false,writable:true,configurable:true})
return u.i}else return H.fn(a,x)},
fn:function(a,b){var z=Object.getPrototypeOf(a)
Object.defineProperty(z,init.dispatchPropertyName,{value:J.cf(b,z,null,null),enumerable:false,writable:true,configurable:true})
return b},
dc:function(a){return J.cf(a,!1,null,!!a.$isZ)},
lX:function(a,b,c){var z=b.prototype
if(init.leafTags[a]===true)return J.cf(z,!1,null,!!z.$isZ)
else return J.cf(z,c,null,null)},
lM:function(){if(!0===$.db)return
$.db=!0
H.lN()},
lN:function(){var z,y,x,w,v,u,t,s
$.c9=Object.create(null)
$.ce=Object.create(null)
H.lI()
z=init.interceptorsByTag
y=Object.getOwnPropertyNames(z)
if(typeof window!="undefined"){window
x=function(){}
for(w=0;w<y.length;++w){v=y[w]
u=$.fo.$1(v)
if(u!=null){t=H.lX(v,z[v],u)
if(t!=null){Object.defineProperty(u,init.dispatchPropertyName,{value:t,enumerable:false,writable:true,configurable:true})
x.prototype=u}}}}for(w=0;w<y.length;++w){v=y[w]
if(/^[A-Za-z_]/.test(v)){s=z[v]
z["!"+v]=s
z["~"+v]=s
z["-"+v]=s
z["+"+v]=s
z["*"+v]=s}}},
lI:function(){var z,y,x,w,v,u,t
z=C.C()
z=H.aX(C.z,H.aX(C.E,H.aX(C.p,H.aX(C.p,H.aX(C.D,H.aX(C.A,H.aX(C.B(C.q),z)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){y=dartNativeDispatchHooksTransformer
if(typeof y=="function")y=[y]
if(y.constructor==Array)for(x=0;x<y.length;++x){w=y[x]
if(typeof w=="function")z=w(z)||z}}v=z.getTag
u=z.getUnknownTag
t=z.prototypeForTag
$.da=new H.lJ(v)
$.fc=new H.lK(u)
$.fo=new H.lL(t)},
aX:function(a,b){return a(b)||b},
m8:function(a,b,c){var z=a.indexOf(b,c)
return z>=0},
dd:function(a,b,c){var z,y,x
H.d6(c)
if(b==="")if(a==="")return c
else{z=a.length
y=H.b(c)
for(x=0;x<z;++x)y=y+a[x]+H.b(c)
return y.charCodeAt(0)==0?y:y}else return a.replace(new RegExp(b.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&"),'g'),c.replace(/\$/g,"$$$$"))},
ha:{"^":"eH;a,$ti",$aseH:I.R,$asG:I.R,$isG:1},
h9:{"^":"e;",
gD:function(a){return this.gi(this)===0},
gU:function(a){return this.gi(this)!==0},
j:function(a){return P.cL(this)},
l:function(a,b,c){return H.dA()},
A:function(a,b){return H.dA()},
$isG:1},
hb:{"^":"h9;a,b,c,$ti",
gi:function(a){return this.a},
N:function(a){if(typeof a!=="string")return!1
if("__proto__"===a)return!1
return this.b.hasOwnProperty(a)},
h:function(a,b){if(!this.N(b))return
return this.dG(b)},
dG:function(a){return this.b[a]},
K:function(a,b){var z,y,x,w
z=this.c
for(y=z.length,x=0;x<y;++x){w=z[x]
b.$2(w,this.dG(w))}},
gM:function(){return new H.k_(this,[H.F(this,0)])}},
k_:{"^":"Q;a,$ti",
gE:function(a){var z=this.a.c
return new J.bo(z,z.length,0,null)},
gi:function(a){return this.a.c.length}},
ii:{"^":"e;a,b,c,d,e,f",
geB:function(){var z=this.a
return z},
geI:function(){var z,y,x,w
if(this.c===1)return C.i
z=this.d
y=z.length-this.e.length
if(y===0)return C.i
x=[]
for(w=0;w<y;++w){if(w>=z.length)return H.a(z,w)
x.push(z[w])}x.fixed$length=Array
x.immutable$list=Array
return x},
geC:function(){var z,y,x,w,v,u,t,s,r
if(this.c!==0)return C.r
z=this.e
y=z.length
x=this.d
w=x.length-y
if(y===0)return C.r
v=P.bC
u=new H.a2(0,null,null,null,null,null,0,[v,null])
for(t=0;t<y;++t){if(t>=z.length)return H.a(z,t)
s=z[t]
r=w+t
if(r<0||r>=x.length)return H.a(x,r)
u.l(0,new H.cR(s),x[r])}return new H.ha(u,[v,null])}},
jd:{"^":"e;a,b,c,d,e,f,r,x",
hX:function(a,b){var z=this.d
if(typeof b!=="number")return b.ak()
if(b<z)return
return this.b[3+b-z]},
w:{
eh:function(a){var z,y,x
z=a.$reflectionInfo
if(z==null)return
z.fixed$length=Array
z=z
y=z[0]
x=z[1]
return new H.jd(a,z,(y&1)===1,y>>1,x>>1,(x&1)===1,z[2],null)}}},
iY:{"^":"f:9;a,b,c",
$2:function(a,b){var z=this.a
z.b=z.b+"$"+H.b(a)
this.c.push(a)
this.b.push(b);++z.a}},
jI:{"^":"e;a,b,c,d,e,f",
a9:function(a){var z,y,x
z=new RegExp(this.a).exec(a)
if(z==null)return
y=Object.create(null)
x=this.b
if(x!==-1)y.arguments=z[x+1]
x=this.c
if(x!==-1)y.argumentsExpr=z[x+1]
x=this.d
if(x!==-1)y.expr=z[x+1]
x=this.e
if(x!==-1)y.method=z[x+1]
x=this.f
if(x!==-1)y.receiver=z[x+1]
return y},
w:{
am:function(a){var z,y,x,w,v,u
a=a.replace(String({}),'$receiver$').replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
z=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(z==null)z=[]
y=z.indexOf("\\$arguments\\$")
x=z.indexOf("\\$argumentsExpr\\$")
w=z.indexOf("\\$expr\\$")
v=z.indexOf("\\$method\\$")
u=z.indexOf("\\$receiver\\$")
return new H.jI(a.replace(new RegExp('\\\\\\$arguments\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$argumentsExpr\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$expr\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$method\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$receiver\\\\\\$','g'),'((?:x|[^x])*)'),y,x,w,v,u)},
c2:function(a){return function($expr$){var $argumentsExpr$='$arguments$'
try{$expr$.$method$($argumentsExpr$)}catch(z){return z.message}}(a)},
eC:function(a){return function($expr$){try{$expr$.$method$}catch(z){return z.message}}(a)}}},
e4:{"^":"P;a,b",
j:function(a){var z=this.b
if(z==null)return"NullError: "+H.b(this.a)
return"NullError: method not found: '"+H.b(z)+"' on null"}},
it:{"^":"P;a,b,c",
j:function(a){var z,y
z=this.b
if(z==null)return"NoSuchMethodError: "+H.b(this.a)
y=this.c
if(y==null)return"NoSuchMethodError: method not found: '"+z+"' ("+H.b(this.a)+")"
return"NoSuchMethodError: method not found: '"+z+"' on '"+y+"' ("+H.b(this.a)+")"},
w:{
cH:function(a,b){var z,y
z=b==null
y=z?null:b.method
return new H.it(a,y,z?null:b.receiver)}}},
jK:{"^":"P;a",
j:function(a){var z=this.a
return z.length===0?"Error":"Error: "+z}},
ma:{"^":"f:0;a",
$1:function(a){if(!!J.j(a).$isP)if(a.$thrownJsError==null)a.$thrownJsError=this.a
return a}},
eV:{"^":"e;a,b",
j:function(a){var z,y
z=this.b
if(z!=null)return z
z=this.a
y=z!==null&&typeof z==="object"?z.stack:null
z=y==null?"":y
this.b=z
return z}},
lP:{"^":"f:2;a",
$0:function(){return this.a.$0()}},
lQ:{"^":"f:2;a,b",
$0:function(){return this.a.$1(this.b)}},
lR:{"^":"f:2;a,b,c",
$0:function(){return this.a.$2(this.b,this.c)}},
lS:{"^":"f:2;a,b,c,d",
$0:function(){return this.a.$3(this.b,this.c,this.d)}},
lT:{"^":"f:2;a,b,c,d,e",
$0:function(){return this.a.$4(this.b,this.c,this.d,this.e)}},
f:{"^":"e;",
j:function(a){return"Closure '"+H.c0(this).trim()+"'"},
geY:function(){return this},
$iscC:1,
geY:function(){return this}},
er:{"^":"f;"},
jn:{"^":"er;",
j:function(a){var z=this.$static_name
if(z==null)return"Closure of unknown static method"
return"Closure '"+z+"'"}},
cs:{"^":"er;a,b,c,d",
G:function(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof H.cs))return!1
return this.a===b.a&&this.b===b.b&&this.c===b.c},
gI:function(a){var z,y
z=this.c
if(z==null)y=H.ax(this.a)
else y=typeof z!=="object"?J.a0(z):H.ax(z)
return J.fs(y,H.ax(this.b))},
j:function(a){var z=this.c
if(z==null)z=this.a
return"Closure '"+H.b(this.d)+"' of "+H.c_(z)},
w:{
ct:function(a){return a.a},
dw:function(a){return a.c},
h0:function(){var z=$.b3
if(z==null){z=H.bN("self")
$.b3=z}return z},
bN:function(a){var z,y,x,w,v
z=new H.cs("self","target","receiver","name")
y=Object.getOwnPropertyNames(z)
y.fixed$length=Array
x=y
for(y=x.length,w=0;w<y;++w){v=x[w]
if(z[v]===a)return v}}}},
h1:{"^":"P;a",
j:function(a){return this.a},
w:{
dx:function(a,b){return new H.h1("CastError: Casting value of type '"+a+"' to incompatible type '"+b+"'")}}},
jf:{"^":"P;a",
j:function(a){return"RuntimeError: "+H.b(this.a)}},
a2:{"^":"e;a,b,c,d,e,f,r,$ti",
gi:function(a){return this.a},
gD:function(a){return this.a===0},
gU:function(a){return!this.gD(this)},
gM:function(){return new H.iA(this,[H.F(this,0)])},
gd7:function(a){return H.bW(this.gM(),new H.is(this),H.F(this,0),H.F(this,1))},
N:function(a){var z,y
if(typeof a==="string"){z=this.b
if(z==null)return!1
return this.dD(z,a)}else if(typeof a==="number"&&(a&0x3ffffff)===a){y=this.c
if(y==null)return!1
return this.dD(y,a)}else return this.ip(a)},
ip:function(a){var z=this.d
if(z==null)return!1
return this.bb(this.bv(z,this.ba(a)),a)>=0},
h:function(a,b){var z,y,x
if(typeof b==="string"){z=this.b
if(z==null)return
y=this.aY(z,b)
return y==null?null:y.gay()}else if(typeof b==="number"&&(b&0x3ffffff)===b){x=this.c
if(x==null)return
y=this.aY(x,b)
return y==null?null:y.gay()}else return this.iq(b)},
iq:function(a){var z,y,x
z=this.d
if(z==null)return
y=this.bv(z,this.ba(a))
x=this.bb(y,a)
if(x<0)return
return y[x].gay()},
l:function(a,b,c){var z,y,x,w,v,u
if(typeof b==="string"){z=this.b
if(z==null){z=this.co()
this.b=z}this.dl(z,b,c)}else if(typeof b==="number"&&(b&0x3ffffff)===b){y=this.c
if(y==null){y=this.co()
this.c=y}this.dl(y,b,c)}else{x=this.d
if(x==null){x=this.co()
this.d=x}w=this.ba(b)
v=this.bv(x,w)
if(v==null)this.cw(x,w,[this.cp(b,c)])
else{u=this.bb(v,b)
if(u>=0)v[u].say(c)
else v.push(this.cp(b,c))}}},
A:function(a,b){if(typeof b==="string")return this.dW(this.b,b)
else if(typeof b==="number"&&(b&0x3ffffff)===b)return this.dW(this.c,b)
else return this.ir(b)},
ir:function(a){var z,y,x,w
z=this.d
if(z==null)return
y=this.bv(z,this.ba(a))
x=this.bb(y,a)
if(x<0)return
w=y.splice(x,1)[0]
this.e4(w)
return w.gay()},
a8:function(a){if(this.a>0){this.f=null
this.e=null
this.d=null
this.c=null
this.b=null
this.a=0
this.r=this.r+1&67108863}},
K:function(a,b){var z,y
z=this.e
y=this.r
for(;z!=null;){b.$2(z.a,z.b)
if(y!==this.r)throw H.c(new P.a8(this))
z=z.c}},
dl:function(a,b,c){var z=this.aY(a,b)
if(z==null)this.cw(a,b,this.cp(b,c))
else z.say(c)},
dW:function(a,b){var z
if(a==null)return
z=this.aY(a,b)
if(z==null)return
this.e4(z)
this.dE(a,b)
return z.gay()},
cp:function(a,b){var z,y
z=new H.iz(a,b,null,null)
if(this.e==null){this.f=z
this.e=z}else{y=this.f
z.d=y
y.c=z
this.f=z}++this.a
this.r=this.r+1&67108863
return z},
e4:function(a){var z,y
z=a.ghf()
y=a.ghd()
if(z==null)this.e=y
else z.c=y
if(y==null)this.f=z
else y.d=z;--this.a
this.r=this.r+1&67108863},
ba:function(a){return J.a0(a)&0x3ffffff},
bb:function(a,b){var z,y
if(a==null)return-1
z=a.length
for(y=0;y<z;++y)if(J.J(a[y].gev(),b))return y
return-1},
j:function(a){return P.cL(this)},
aY:function(a,b){return a[b]},
bv:function(a,b){return a[b]},
cw:function(a,b,c){a[b]=c},
dE:function(a,b){delete a[b]},
dD:function(a,b){return this.aY(a,b)!=null},
co:function(){var z=Object.create(null)
this.cw(z,"<non-identifier-key>",z)
this.dE(z,"<non-identifier-key>")
return z},
$isi6:1,
$isG:1},
is:{"^":"f:0;a",
$1:[function(a){return this.a.h(0,a)},null,null,2,0,null,19,"call"]},
iz:{"^":"e;ev:a<,ay:b@,hd:c<,hf:d<"},
iA:{"^":"i;a,$ti",
gi:function(a){return this.a.a},
gD:function(a){return this.a.a===0},
gE:function(a){var z,y
z=this.a
y=new H.iB(z,z.r,null,null)
y.c=z.e
return y}},
iB:{"^":"e;a,b,c,d",
gq:function(){return this.d},
m:function(){var z=this.a
if(this.b!==z.r)throw H.c(new P.a8(z))
else{z=this.c
if(z==null){this.d=null
return!1}else{this.d=z.a
this.c=z.c
return!0}}}},
lJ:{"^":"f:0;a",
$1:function(a){return this.a(a)}},
lK:{"^":"f:10;a",
$2:function(a,b){return this.a(a,b)}},
lL:{"^":"f:11;a",
$1:function(a){return this.a(a)}},
io:{"^":"e;a,b,c,d",
j:function(a){return"RegExp/"+this.a+"/"},
ghc:function(){var z=this.d
if(z!=null)return z
z=this.b
z=H.dV(this.a+"|()",z.multiline,!z.ignoreCase,!0)
this.d=z
return z},
h_:function(a,b){var z,y
z=this.ghc()
z.lastIndex=b
y=z.exec(a)
if(y==null)return
if(0>=y.length)return H.a(y,-1)
if(y.pop()!=null)return
return new H.kH(this,y)},
eA:function(a,b,c){if(c>b.length)throw H.c(P.H(c,0,b.length,null,null))
return this.h_(b,c)},
w:{
dV:function(a,b,c,d){var z,y,x,w
z=b?"m":""
y=c?"":"i"
x=d?"g":""
w=function(e,f){try{return new RegExp(e,f)}catch(v){return v}}(a,z+y+x)
if(w instanceof RegExp)return w
throw H.c(new P.bR("Illegal RegExp pattern ("+String(w)+")",a,null))}}},
kH:{"^":"e;a,b",
h:function(a,b){var z=this.b
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]}},
js:{"^":"e;a,b,c",
h:function(a,b){if(b!==0)H.B(P.ba(b,null,null))
return this.c}}}],["","",,H,{"^":"",
lD:function(a){var z=H.q(a?Object.keys(a):[],[null])
z.fixed$length=Array
return z}}],["","",,H,{"^":"",
m4:function(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof window=="object")return
if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)}}],["","",,H,{"^":"",dX:{"^":"k;",$isdX:1,"%":"ArrayBuffer"},bZ:{"^":"k;",
h6:function(a,b,c,d){var z=P.H(b,0,c,d,null)
throw H.c(z)},
dt:function(a,b,c,d){if(b>>>0!==b||b>c)this.h6(a,b,c,d)},
$isbZ:1,
$isa9:1,
"%":";ArrayBufferView;cM|dY|e_|bY|dZ|e0|aw"},nb:{"^":"bZ;",$isa9:1,"%":"DataView"},cM:{"^":"bZ;",
gi:function(a){return a.length},
e0:function(a,b,c,d,e){var z,y,x
z=a.length
this.dt(a,b,z,"start")
this.dt(a,c,z,"end")
if(b>c)throw H.c(P.H(b,0,c,null,null))
y=c-b
x=d.length
if(x-e<y)throw H.c(new P.a5("Not enough elements"))
if(e!==0||x!==y)d=d.subarray(e,e+y)
a.set(d,b)},
$isZ:1,
$asZ:I.R,
$isT:1,
$asT:I.R},bY:{"^":"e_;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
l:function(a,b,c){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
a[b]=c},
Z:function(a,b,c,d,e){if(!!J.j(d).$isbY){this.e0(a,b,c,d,e)
return}this.dg(a,b,c,d,e)}},dY:{"^":"cM+X;",$asZ:I.R,$asT:I.R,
$ash:function(){return[P.ap]},
$asi:function(){return[P.ap]},
$ish:1,
$isi:1},e_:{"^":"dY+dN;",$asZ:I.R,$asT:I.R,
$ash:function(){return[P.ap]},
$asi:function(){return[P.ap]}},aw:{"^":"e0;",
l:function(a,b,c){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
a[b]=c},
Z:function(a,b,c,d,e){if(!!J.j(d).$isaw){this.e0(a,b,c,d,e)
return}this.dg(a,b,c,d,e)},
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]}},dZ:{"^":"cM+X;",$asZ:I.R,$asT:I.R,
$ash:function(){return[P.y]},
$asi:function(){return[P.y]},
$ish:1,
$isi:1},e0:{"^":"dZ+dN;",$asZ:I.R,$asT:I.R,
$ash:function(){return[P.y]},
$asi:function(){return[P.y]}},nc:{"^":"bY;",$isa9:1,$ish:1,
$ash:function(){return[P.ap]},
$isi:1,
$asi:function(){return[P.ap]},
"%":"Float32Array"},nd:{"^":"bY;",$isa9:1,$ish:1,
$ash:function(){return[P.ap]},
$isi:1,
$asi:function(){return[P.ap]},
"%":"Float64Array"},ne:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa9:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Int16Array"},nf:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa9:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Int32Array"},ng:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa9:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Int8Array"},nh:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa9:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Uint16Array"},ni:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa9:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Uint32Array"},nj:{"^":"aw;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa9:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"CanvasPixelArray|Uint8ClampedArray"},nk:{"^":"aw;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa9:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":";Uint8Array"}}],["","",,P,{"^":"",
jO:function(){var z,y,x
z={}
if(self.scheduleImmediate!=null)return P.ls()
if(self.MutationObserver!=null&&self.document!=null){y=self.document.createElement("div")
x=self.document.createElement("span")
z.a=null
new self.MutationObserver(H.aY(new P.jQ(z),1)).observe(y,{childList:true})
return new P.jP(z,y,x)}else if(self.setImmediate!=null)return P.lt()
return P.lu()},
nU:[function(a){++init.globalState.f.b
self.scheduleImmediate(H.aY(new P.jR(a),0))},"$1","ls",2,0,4],
nV:[function(a){++init.globalState.f.b
self.setImmediate(H.aY(new P.jS(a),0))},"$1","lt",2,0,4],
nW:[function(a){P.cS(C.o,a)},"$1","lu",2,0,4],
lh:function(a,b,c){if(H.aK(a,{func:1,args:[P.b8,P.b8]}))return a.$2(b,c)
else return a.$1(b)},
f4:function(a,b){if(H.aK(a,{func:1,args:[P.b8,P.b8]})){b.toString
return a}else{b.toString
return a}},
lj:function(){var z,y
for(;z=$.aU,z!=null;){$.be=null
y=z.ga_()
$.aU=y
if(y==null)$.bd=null
z.gef().$0()}},
oc:[function(){$.d4=!0
try{P.lj()}finally{$.be=null
$.d4=!1
if($.aU!=null)$.$get$cV().$1(P.fg())}},"$0","fg",0,0,1],
f9:function(a){var z=new P.eI(a,null)
if($.aU==null){$.bd=z
$.aU=z
if(!$.d4)$.$get$cV().$1(P.fg())}else{$.bd.b=z
$.bd=z}},
ln:function(a){var z,y,x
z=$.aU
if(z==null){P.f9(a)
$.be=$.bd
return}y=new P.eI(a,null)
x=$.be
if(x==null){y.b=z
$.be=y
$.aU=y}else{y.b=x.b
x.b=y
$.be=y
if(y.b==null)$.bd=y}},
fp:function(a){var z=$.x
if(C.c===z){P.aW(null,null,C.c,a)
return}z.toString
P.aW(null,null,z,z.cD(a,!0))},
f8:function(a){var z,y,x,w
if(a==null)return
try{a.$0()}catch(x){z=H.D(x)
y=H.a_(x)
w=$.x
w.toString
P.aV(null,null,w,z,y)}},
oa:[function(a){},"$1","lv",2,0,19,2],
lk:[function(a,b){var z=$.x
z.toString
P.aV(null,null,z,a,b)},function(a){return P.lk(a,null)},"$2","$1","lw",2,2,3,1],
ob:[function(){},"$0","ff",0,0,1],
eY:function(a,b,c){$.x.toString
a.aE(b,c)},
jA:function(a,b){var z=$.x
if(z===C.c){z.toString
return P.cS(a,b)}return P.cS(a,z.cD(b,!0))},
cS:function(a,b){var z=C.f.bF(a.a,1000)
return H.jx(z<0?0:z,b)},
jN:function(){return $.x},
aV:function(a,b,c,d,e){var z={}
z.a=d
P.ln(new P.lm(z,e))},
f5:function(a,b,c,d){var z,y
y=$.x
if(y===c)return d.$0()
$.x=c
z=y
try{y=d.$0()
return y}finally{$.x=z}},
f7:function(a,b,c,d,e){var z,y
y=$.x
if(y===c)return d.$1(e)
$.x=c
z=y
try{y=d.$1(e)
return y}finally{$.x=z}},
f6:function(a,b,c,d,e,f){var z,y
y=$.x
if(y===c)return d.$2(e,f)
$.x=c
z=y
try{y=d.$2(e,f)
return y}finally{$.x=z}},
aW:function(a,b,c,d){var z=C.c!==c
if(z)d=c.cD(d,!(!z||!1))
P.f9(d)},
jQ:{"^":"f:0;a",
$1:[function(a){var z,y;--init.globalState.f.b
z=this.a
y=z.a
z.a=null
y.$0()},null,null,2,0,null,5,"call"]},
jP:{"^":"f:12;a,b,c",
$1:function(a){var z,y;++init.globalState.f.b
this.a.a=a
z=this.b
y=this.c
z.firstChild?z.removeChild(y):z.appendChild(y)}},
jR:{"^":"f:2;a",
$0:[function(){--init.globalState.f.b
this.a.$0()},null,null,0,0,null,"call"]},
jS:{"^":"f:2;a",
$0:[function(){--init.globalState.f.b
this.a.$0()},null,null,0,0,null,"call"]},
jU:{"^":"eK;a,$ti"},
jV:{"^":"k0;aU:y@,ad:z@,br:Q@,x,a,b,c,d,e,f,r,$ti",
h0:function(a){return(this.y&1)===a},
hC:function(){this.y^=1},
gh8:function(){return(this.y&2)!==0},
hy:function(){this.y|=4},
ghk:function(){return(this.y&4)!==0},
bx:[function(){},"$0","gbw",0,0,1],
bz:[function(){},"$0","gby",0,0,1]},
cW:{"^":"e;ab:c<,$ti",
gbc:function(){return!1},
gaZ:function(){return this.c<4},
fY:function(){var z=this.r
if(z!=null)return z
z=new P.ao(0,$.x,null,[null])
this.r=z
return z},
aQ:function(a){var z
a.saU(this.c&1)
z=this.e
this.e=a
a.sad(null)
a.sbr(z)
if(z==null)this.d=a
else z.sad(a)},
dX:function(a){var z,y
z=a.gbr()
y=a.gad()
if(z==null)this.d=y
else z.sad(y)
if(y==null)this.e=z
else y.sbr(z)
a.sbr(a)
a.sad(a)},
hB:function(a,b,c,d){var z,y,x
if((this.c&4)!==0){if(c==null)c=P.ff()
z=new P.k6($.x,0,c,this.$ti)
z.e_()
return z}z=$.x
y=d?1:0
x=new P.jV(0,null,null,this,null,null,null,z,y,null,null,this.$ti)
x.dj(a,b,c,d,H.F(this,0))
x.Q=x
x.z=x
this.aQ(x)
z=this.d
y=this.e
if(z==null?y==null:z===y)P.f8(this.a)
return x},
hh:function(a){if(a.gad()===a)return
if(a.gh8())a.hy()
else{this.dX(a)
if((this.c&2)===0&&this.d==null)this.c6()}return},
hi:function(a){},
hj:function(a){},
bq:["fo",function(){if((this.c&4)!==0)return new P.a5("Cannot add new events after calling close")
return new P.a5("Cannot add new events while doing an addStream")}],
C:[function(a,b){if(!this.gaZ())throw H.c(this.bq())
this.bC(b)},"$1","ghE",2,0,function(){return H.bg(function(a){return{func:1,v:true,args:[a]}},this.$receiver,"cW")}],
hH:[function(a,b){if(!this.gaZ())throw H.c(this.bq())
$.x.toString
this.bD(a,b)},function(a){return this.hH(a,null)},"iZ","$2","$1","ghG",2,2,3,1],
ej:function(a){var z
if((this.c&4)!==0)return this.r
if(!this.gaZ())throw H.c(this.bq())
this.c|=4
z=this.fY()
this.b1()
return z},
ck:function(a){var z,y,x,w
z=this.c
if((z&2)!==0)throw H.c(new P.a5("Cannot fire new event. Controller is already firing an event"))
y=this.d
if(y==null)return
x=z&1
this.c=z^3
for(;y!=null;)if(y.h0(x)){y.saU(y.gaU()|2)
a.$1(y)
y.hC()
w=y.gad()
if(y.ghk())this.dX(y)
y.saU(y.gaU()&4294967293)
y=w}else y=y.gad()
this.c&=4294967293
if(this.d==null)this.c6()},
c6:function(){if((this.c&4)!==0&&this.r.a===0)this.r.dr(null)
P.f8(this.b)}},
c7:{"^":"cW;a,b,c,d,e,f,r,$ti",
gaZ:function(){return P.cW.prototype.gaZ.call(this)===!0&&(this.c&2)===0},
bq:function(){if((this.c&2)!==0)return new P.a5("Cannot fire new event. Controller is already firing an event")
return this.fo()},
bC:function(a){var z=this.d
if(z==null)return
if(z===this.e){this.c|=2
z.aR(a)
this.c&=4294967293
if(this.d==null)this.c6()
return}this.ck(new P.l3(this,a))},
bD:function(a,b){if(this.d==null)return
this.ck(new P.l5(this,a,b))},
b1:function(){if(this.d!=null)this.ck(new P.l4(this))
else this.r.dr(null)}},
l3:{"^":"f;a,b",
$1:function(a){a.aR(this.b)},
$S:function(){return H.bg(function(a){return{func:1,args:[[P.aI,a]]}},this.a,"c7")}},
l5:{"^":"f;a,b,c",
$1:function(a){a.aE(this.b,this.c)},
$S:function(){return H.bg(function(a){return{func:1,args:[[P.aI,a]]}},this.a,"c7")}},
l4:{"^":"f;a",
$1:function(a){a.dq()},
$S:function(){return H.bg(function(a){return{func:1,args:[[P.aI,a]]}},this.a,"c7")}},
jZ:{"^":"e;$ti"},
l6:{"^":"jZ;a,$ti"},
eO:{"^":"e;af:a@,O:b>,c,ef:d<,e",
gar:function(){return this.b.b},
ger:function(){return(this.c&1)!==0},
gil:function(){return(this.c&2)!==0},
geq:function(){return this.c===8},
gim:function(){return this.e!=null},
ij:function(a){return this.b.b.d1(this.d,a)},
iz:function(a){if(this.c!==6)return!0
return this.b.b.d1(this.d,J.bj(a))},
ep:function(a){var z,y,x
z=this.e
y=J.m(a)
x=this.b.b
if(H.aK(z,{func:1,args:[,,]}))return x.iM(z,y.gav(a),a.gal())
else return x.d1(z,y.gav(a))},
ik:function(){return this.b.b.eM(this.d)}},
ao:{"^":"e;ab:a<,ar:b<,aG:c<,$ti",
gh7:function(){return this.a===2},
gcn:function(){return this.a>=4},
gh5:function(){return this.a===8},
hv:function(a){this.a=2
this.c=a},
eQ:function(a,b){var z,y
z=$.x
if(z!==C.c){z.toString
if(b!=null)b=P.f4(b,z)}y=new P.ao(0,$.x,null,[null])
this.aQ(new P.eO(null,y,b==null?1:3,a,b))
return y},
eP:function(a){return this.eQ(a,null)},
eV:function(a){var z,y
z=$.x
y=new P.ao(0,z,null,this.$ti)
if(z!==C.c)z.toString
this.aQ(new P.eO(null,y,8,a,null))
return y},
hx:function(){this.a=1},
fP:function(){this.a=0},
gao:function(){return this.c},
gfM:function(){return this.c},
hz:function(a){this.a=4
this.c=a},
hw:function(a){this.a=8
this.c=a},
du:function(a){this.a=a.gab()
this.c=a.gaG()},
aQ:function(a){var z,y
z=this.a
if(z<=1){a.a=this.c
this.c=a}else{if(z===2){y=this.c
if(!y.gcn()){y.aQ(a)
return}this.a=y.gab()
this.c=y.gaG()}z=this.b
z.toString
P.aW(null,null,z,new P.kf(this,a))}},
dV:function(a){var z,y,x,w,v
z={}
z.a=a
if(a==null)return
y=this.a
if(y<=1){x=this.c
this.c=a
if(x!=null){for(w=a;w.gaf()!=null;)w=w.gaf()
w.saf(x)}}else{if(y===2){v=this.c
if(!v.gcn()){v.dV(a)
return}this.a=v.gab()
this.c=v.gaG()}z.a=this.dY(a)
y=this.b
y.toString
P.aW(null,null,y,new P.kl(z,this))}},
aF:function(){var z=this.c
this.c=null
return this.dY(z)},
dY:function(a){var z,y,x
for(z=a,y=null;z!=null;y=z,z=x){x=z.gaf()
z.saf(y)}return y},
bs:function(a){var z,y
z=this.$ti
if(H.bK(a,"$isaF",z,"$asaF"))if(H.bK(a,"$isao",z,null))P.c5(a,this)
else P.eP(a,this)
else{y=this.aF()
this.a=4
this.c=a
P.aS(this,y)}},
cb:[function(a,b){var z=this.aF()
this.a=8
this.c=new P.bL(a,b)
P.aS(this,z)},function(a){return this.cb(a,null)},"iV","$2","$1","gdC",2,2,3,1,4,6],
dr:function(a){var z
if(H.bK(a,"$isaF",this.$ti,"$asaF")){this.fL(a)
return}this.a=1
z=this.b
z.toString
P.aW(null,null,z,new P.kg(this,a))},
fL:function(a){var z
if(H.bK(a,"$isao",this.$ti,null)){if(a.a===8){this.a=1
z=this.b
z.toString
P.aW(null,null,z,new P.kk(this,a))}else P.c5(a,this)
return}P.eP(a,this)},
fG:function(a,b){this.a=4
this.c=a},
$isaF:1,
w:{
eP:function(a,b){var z,y,x
b.hx()
try{a.eQ(new P.kh(b),new P.ki(b))}catch(x){z=H.D(x)
y=H.a_(x)
P.fp(new P.kj(b,z,y))}},
c5:function(a,b){var z
for(;a.gh7();)a=a.gfM()
if(a.gcn()){z=b.aF()
b.du(a)
P.aS(b,z)}else{z=b.gaG()
b.hv(a)
a.dV(z)}},
aS:function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o
z={}
z.a=a
for(y=a;!0;){x={}
w=y.gh5()
if(b==null){if(w){v=z.a.gao()
y=z.a.gar()
u=J.bj(v)
t=v.gal()
y.toString
P.aV(null,null,y,u,t)}return}for(;b.gaf()!=null;b=s){s=b.gaf()
b.saf(null)
P.aS(z.a,b)}r=z.a.gaG()
x.a=w
x.b=r
y=!w
if(!y||b.ger()||b.geq()){q=b.gar()
if(w){u=z.a.gar()
u.toString
u=u==null?q==null:u===q
if(!u)q.toString
else u=!0
u=!u}else u=!1
if(u){v=z.a.gao()
y=z.a.gar()
u=J.bj(v)
t=v.gal()
y.toString
P.aV(null,null,y,u,t)
return}p=$.x
if(p==null?q!=null:p!==q)$.x=q
else p=null
if(b.geq())new P.ko(z,x,w,b).$0()
else if(y){if(b.ger())new P.kn(x,b,r).$0()}else if(b.gil())new P.km(z,x,b).$0()
if(p!=null)$.x=p
y=x.b
if(!!J.j(y).$isaF){o=J.dl(b)
if(y.a>=4){b=o.aF()
o.du(y)
z.a=y
continue}else P.c5(y,o)
return}}o=J.dl(b)
b=o.aF()
y=x.a
u=x.b
if(!y)o.hz(u)
else o.hw(u)
z.a=o
y=o}}}},
kf:{"^":"f:2;a,b",
$0:function(){P.aS(this.a,this.b)}},
kl:{"^":"f:2;a,b",
$0:function(){P.aS(this.b,this.a.a)}},
kh:{"^":"f:0;a",
$1:[function(a){var z=this.a
z.fP()
z.bs(a)},null,null,2,0,null,2,"call"]},
ki:{"^":"f:13;a",
$2:[function(a,b){this.a.cb(a,b)},function(a){return this.$2(a,null)},"$1",null,null,null,2,2,null,1,4,6,"call"]},
kj:{"^":"f:2;a,b,c",
$0:function(){this.a.cb(this.b,this.c)}},
kg:{"^":"f:2;a,b",
$0:function(){var z,y
z=this.a
y=z.aF()
z.a=4
z.c=this.b
P.aS(z,y)}},
kk:{"^":"f:2;a,b",
$0:function(){P.c5(this.b,this.a)}},
ko:{"^":"f:1;a,b,c,d",
$0:function(){var z,y,x,w,v,u,t
z=null
try{z=this.d.ik()}catch(w){y=H.D(w)
x=H.a_(w)
if(this.c){v=J.bj(this.a.a.gao())
u=y
u=v==null?u==null:v===u
v=u}else v=!1
u=this.b
if(v)u.b=this.a.a.gao()
else u.b=new P.bL(y,x)
u.a=!0
return}if(!!J.j(z).$isaF){if(z instanceof P.ao&&z.gab()>=4){if(z.gab()===8){v=this.b
v.b=z.gaG()
v.a=!0}return}t=this.a.a
v=this.b
v.b=z.eP(new P.kp(t))
v.a=!1}}},
kp:{"^":"f:0;a",
$1:[function(a){return this.a},null,null,2,0,null,5,"call"]},
kn:{"^":"f:1;a,b,c",
$0:function(){var z,y,x,w
try{this.a.b=this.b.ij(this.c)}catch(x){z=H.D(x)
y=H.a_(x)
w=this.a
w.b=new P.bL(z,y)
w.a=!0}}},
km:{"^":"f:1;a,b,c",
$0:function(){var z,y,x,w,v,u,t,s
try{z=this.a.a.gao()
w=this.c
if(w.iz(z)===!0&&w.gim()){v=this.b
v.b=w.ep(z)
v.a=!1}}catch(u){y=H.D(u)
x=H.a_(u)
w=this.a
v=J.bj(w.a.gao())
t=y
s=this.b
if(v==null?t==null:v===t)s.b=w.a.gao()
else s.b=new P.bL(y,x)
s.a=!0}}},
eI:{"^":"e;ef:a<,a_:b@"},
ae:{"^":"e;$ti",
ag:function(a,b){return new P.kG(b,this,[H.I(this,"ae",0),null])},
ie:function(a,b){return new P.kq(a,b,this,[H.I(this,"ae",0)])},
ep:function(a){return this.ie(a,null)},
gi:function(a){var z,y
z={}
y=new P.ao(0,$.x,null,[P.y])
z.a=0
this.a2(new P.jo(z),!0,new P.jp(z,y),y.gdC())
return y},
aM:function(a){var z,y,x
z=H.I(this,"ae",0)
y=H.q([],[z])
x=new P.ao(0,$.x,null,[[P.h,z]])
this.a2(new P.jq(this,y),!0,new P.jr(y,x),x.gdC())
return x}},
jo:{"^":"f:0;a",
$1:[function(a){++this.a.a},null,null,2,0,null,5,"call"]},
jp:{"^":"f:2;a,b",
$0:[function(){this.b.bs(this.a.a)},null,null,0,0,null,"call"]},
jq:{"^":"f;a,b",
$1:[function(a){this.b.push(a)},null,null,2,0,null,11,"call"],
$S:function(){return H.bg(function(a){return{func:1,args:[a]}},this.a,"ae")}},
jr:{"^":"f:2;a,b",
$0:[function(){this.b.bs(this.a)},null,null,0,0,null,"call"]},
en:{"^":"e;$ti"},
eK:{"^":"kZ;a,$ti",
gI:function(a){return(H.ax(this.a)^892482866)>>>0},
G:function(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof P.eK))return!1
return b.a===this.a}},
k0:{"^":"aI;$ti",
cq:function(){return this.x.hh(this)},
bx:[function(){this.x.hi(this)},"$0","gbw",0,0,1],
bz:[function(){this.x.hj(this)},"$0","gby",0,0,1]},
aI:{"^":"e;ar:d<,ab:e<,$ti",
bg:function(a,b){var z=this.e
if((z&8)!==0)return
this.e=(z+128|4)>>>0
if(z<128&&this.r!=null)this.r.eg()
if((z&4)===0&&(this.e&32)===0)this.dN(this.gbw())},
cV:function(a){return this.bg(a,null)},
cZ:function(){var z=this.e
if((z&8)!==0)return
if(z>=128){z-=128
this.e=z
if(z<128){if((z&64)!==0){z=this.r
z=!z.gD(z)}else z=!1
if(z)this.r.bY(this)
else{z=(this.e&4294967291)>>>0
this.e=z
if((z&32)===0)this.dN(this.gby())}}}},
aJ:function(){var z=(this.e&4294967279)>>>0
this.e=z
if((z&8)===0)this.c7()
z=this.f
return z==null?$.$get$bt():z},
gbc:function(){return this.e>=128},
c7:function(){var z=(this.e|8)>>>0
this.e=z
if((z&64)!==0)this.r.eg()
if((this.e&32)===0)this.r=null
this.f=this.cq()},
aR:["fp",function(a){var z=this.e
if((z&8)!==0)return
if(z<32)this.bC(a)
else this.c5(new P.k3(a,null,[H.I(this,"aI",0)]))}],
aE:["fq",function(a,b){var z=this.e
if((z&8)!==0)return
if(z<32)this.bD(a,b)
else this.c5(new P.k5(a,b,null))}],
dq:function(){var z=this.e
if((z&8)!==0)return
z=(z|2)>>>0
this.e=z
if(z<32)this.b1()
else this.c5(C.w)},
bx:[function(){},"$0","gbw",0,0,1],
bz:[function(){},"$0","gby",0,0,1],
cq:function(){return},
c5:function(a){var z,y
z=this.r
if(z==null){z=new P.l_(null,null,0,[H.I(this,"aI",0)])
this.r=z}z.C(0,a)
y=this.e
if((y&64)===0){y=(y|64)>>>0
this.e=y
if(y<128)this.r.bY(this)}},
bC:function(a){var z=this.e
this.e=(z|32)>>>0
this.d.d2(this.a,a)
this.e=(this.e&4294967263)>>>0
this.c9((z&4)!==0)},
bD:function(a,b){var z,y
z=this.e
y=new P.jX(this,a,b)
if((z&1)!==0){this.e=(z|16)>>>0
this.c7()
z=this.f
if(!!J.j(z).$isaF&&z!==$.$get$bt())z.eV(y)
else y.$0()}else{y.$0()
this.c9((z&4)!==0)}},
b1:function(){var z,y
z=new P.jW(this)
this.c7()
this.e=(this.e|16)>>>0
y=this.f
if(!!J.j(y).$isaF&&y!==$.$get$bt())y.eV(z)
else z.$0()},
dN:function(a){var z=this.e
this.e=(z|32)>>>0
a.$0()
this.e=(this.e&4294967263)>>>0
this.c9((z&4)!==0)},
c9:function(a){var z,y
if((this.e&64)!==0){z=this.r
z=z.gD(z)}else z=!1
if(z){z=(this.e&4294967231)>>>0
this.e=z
if((z&4)!==0)if(z<128){z=this.r
z=z==null||z.gD(z)}else z=!1
else z=!1
if(z)this.e=(this.e&4294967291)>>>0}for(;!0;a=y){z=this.e
if((z&8)!==0){this.r=null
return}y=(z&4)!==0
if(a===y)break
this.e=(z^32)>>>0
if(y)this.bx()
else this.bz()
this.e=(this.e&4294967263)>>>0}z=this.e
if((z&64)!==0&&z<128)this.r.bY(this)},
dj:function(a,b,c,d,e){var z,y
z=a==null?P.lv():a
y=this.d
y.toString
this.a=z
this.b=P.f4(b==null?P.lw():b,y)
this.c=c==null?P.ff():c}},
jX:{"^":"f:1;a,b,c",
$0:function(){var z,y,x,w,v,u
z=this.a
y=z.e
if((y&8)!==0&&(y&16)===0)return
z.e=(y|32)>>>0
y=z.b
x=H.aK(y,{func:1,args:[P.e,P.bB]})
w=z.d
v=this.b
u=z.b
if(x)w.iN(u,v,this.c)
else w.d2(u,v)
z.e=(z.e&4294967263)>>>0}},
jW:{"^":"f:1;a",
$0:function(){var z,y
z=this.a
y=z.e
if((y&16)===0)return
z.e=(y|42)>>>0
z.d.d0(z.c)
z.e=(z.e&4294967263)>>>0}},
kZ:{"^":"ae;$ti",
a2:function(a,b,c,d){return this.a.hB(a,d,c,!0===b)},
be:function(a,b,c){return this.a2(a,null,b,c)}},
eL:{"^":"e;a_:a@"},
k3:{"^":"eL;b,a,$ti",
cW:function(a){a.bC(this.b)}},
k5:{"^":"eL;av:b>,al:c<,a",
cW:function(a){a.bD(this.b,this.c)}},
k4:{"^":"e;",
cW:function(a){a.b1()},
ga_:function(){return},
sa_:function(a){throw H.c(new P.a5("No events after a done."))}},
kO:{"^":"e;ab:a<",
bY:function(a){var z=this.a
if(z===1)return
if(z>=1){this.a=1
return}P.fp(new P.kP(this,a))
this.a=1},
eg:function(){if(this.a===1)this.a=3}},
kP:{"^":"f:2;a,b",
$0:function(){var z,y,x,w
z=this.a
y=z.a
z.a=0
if(y===3)return
x=z.b
w=x.ga_()
z.b=w
if(w==null)z.c=null
x.cW(this.b)}},
l_:{"^":"kO;b,c,a,$ti",
gD:function(a){return this.c==null},
C:function(a,b){var z=this.c
if(z==null){this.c=b
this.b=b}else{z.sa_(b)
this.c=b}}},
k6:{"^":"e;ar:a<,ab:b<,c,$ti",
gbc:function(){return this.b>=4},
e_:function(){if((this.b&2)!==0)return
var z=this.a
z.toString
P.aW(null,null,z,this.ghu())
this.b=(this.b|2)>>>0},
bg:function(a,b){this.b+=4},
cV:function(a){return this.bg(a,null)},
cZ:function(){var z=this.b
if(z>=4){z-=4
this.b=z
if(z<4&&(z&1)===0)this.e_()}},
aJ:function(){return $.$get$bt()},
b1:[function(){var z=(this.b&4294967293)>>>0
this.b=z
if(z>=4)return
this.b=(z|1)>>>0
z=this.c
if(z!=null)this.a.d0(z)},"$0","ghu",0,0,1]},
bE:{"^":"ae;$ti",
a2:function(a,b,c,d){return this.fS(a,d,c,!0===b)},
be:function(a,b,c){return this.a2(a,null,b,c)},
fS:function(a,b,c,d){return P.ke(this,a,b,c,d,H.I(this,"bE",0),H.I(this,"bE",1))},
dO:function(a,b){b.aR(a)},
dP:function(a,b,c){c.aE(a,b)},
$asae:function(a,b){return[b]}},
eN:{"^":"aI;x,y,a,b,c,d,e,f,r,$ti",
aR:function(a){if((this.e&2)!==0)return
this.fp(a)},
aE:function(a,b){if((this.e&2)!==0)return
this.fq(a,b)},
bx:[function(){var z=this.y
if(z==null)return
z.cV(0)},"$0","gbw",0,0,1],
bz:[function(){var z=this.y
if(z==null)return
z.cZ()},"$0","gby",0,0,1],
cq:function(){var z=this.y
if(z!=null){this.y=null
return z.aJ()}return},
iW:[function(a){this.x.dO(a,this)},"$1","gh2",2,0,function(){return H.bg(function(a,b){return{func:1,v:true,args:[a]}},this.$receiver,"eN")},11],
iY:[function(a,b){this.x.dP(a,b,this)},"$2","gh4",4,0,14,4,6],
iX:[function(){this.dq()},"$0","gh3",0,0,1],
fF:function(a,b,c,d,e,f,g){this.y=this.x.a.be(this.gh2(),this.gh3(),this.gh4())},
$asaI:function(a,b){return[b]},
w:{
ke:function(a,b,c,d,e,f,g){var z,y
z=$.x
y=e?1:0
y=new P.eN(a,null,null,null,null,z,y,null,null,[f,g])
y.dj(b,c,d,e,g)
y.fF(a,b,c,d,e,f,g)
return y}}},
kG:{"^":"bE;b,a,$ti",
dO:function(a,b){var z,y,x,w
z=null
try{z=this.b.$1(a)}catch(w){y=H.D(w)
x=H.a_(w)
P.eY(b,y,x)
return}b.aR(z)}},
kq:{"^":"bE;b,c,a,$ti",
dP:function(a,b,c){var z,y,x,w,v
z=!0
if(z===!0)try{P.lh(this.b,a,b)}catch(w){y=H.D(w)
x=H.a_(w)
v=y
if(v==null?a==null:v===a)c.aE(a,b)
else P.eY(c,y,x)
return}else c.aE(a,b)},
$asbE:function(a){return[a,a]},
$asae:null},
bL:{"^":"e;av:a>,al:b<",
j:function(a){return H.b(this.a)},
$isP:1},
lb:{"^":"e;"},
lm:{"^":"f:2;a,b",
$0:function(){var z,y,x
z=this.a
y=z.a
if(y==null){x=new P.e5()
z.a=x
z=x}else z=y
y=this.b
if(y==null)throw H.c(z)
x=H.c(z)
x.stack=J.C(y)
throw x}},
kR:{"^":"lb;",
d0:function(a){var z,y,x,w
try{if(C.c===$.x){x=a.$0()
return x}x=P.f5(null,null,this,a)
return x}catch(w){z=H.D(w)
y=H.a_(w)
x=P.aV(null,null,this,z,y)
return x}},
d2:function(a,b){var z,y,x,w
try{if(C.c===$.x){x=a.$1(b)
return x}x=P.f7(null,null,this,a,b)
return x}catch(w){z=H.D(w)
y=H.a_(w)
x=P.aV(null,null,this,z,y)
return x}},
iN:function(a,b,c){var z,y,x,w
try{if(C.c===$.x){x=a.$2(b,c)
return x}x=P.f6(null,null,this,a,b,c)
return x}catch(w){z=H.D(w)
y=H.a_(w)
x=P.aV(null,null,this,z,y)
return x}},
cD:function(a,b){if(b)return new P.kS(this,a)
else return new P.kT(this,a)},
hN:function(a,b){return new P.kU(this,a)},
h:function(a,b){return},
eM:function(a){if($.x===C.c)return a.$0()
return P.f5(null,null,this,a)},
d1:function(a,b){if($.x===C.c)return a.$1(b)
return P.f7(null,null,this,a,b)},
iM:function(a,b,c){if($.x===C.c)return a.$2(b,c)
return P.f6(null,null,this,a,b,c)}},
kS:{"^":"f:2;a,b",
$0:function(){return this.a.d0(this.b)}},
kT:{"^":"f:2;a,b",
$0:function(){return this.a.eM(this.b)}},
kU:{"^":"f:0;a,b",
$1:[function(a){return this.a.d2(this.b,a)},null,null,2,0,null,23,"call"]}}],["","",,P,{"^":"",
iC:function(a,b){return new H.a2(0,null,null,null,null,null,0,[a,b])},
bA:function(){return new H.a2(0,null,null,null,null,null,0,[null,null])},
au:function(a){return H.lE(a,new H.a2(0,null,null,null,null,null,0,[null,null]))},
ie:function(a,b,c){var z,y
if(P.d5(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}z=[]
y=$.$get$bf()
y.push(a)
try{P.li(a,z)}finally{if(0>=y.length)return H.a(y,-1)
y.pop()}y=P.eo(b,z,", ")+c
return y.charCodeAt(0)==0?y:y},
bS:function(a,b,c){var z,y,x
if(P.d5(a))return b+"..."+c
z=new P.aH(b)
y=$.$get$bf()
y.push(a)
try{x=z
x.sk(P.eo(x.gk(),a,", "))}finally{if(0>=y.length)return H.a(y,-1)
y.pop()}y=z
y.sk(y.gk()+c)
y=z.gk()
return y.charCodeAt(0)==0?y:y},
d5:function(a){var z,y
for(z=0;y=$.$get$bf(),z<y.length;++z)if(a===y[z])return!0
return!1},
li:function(a,b){var z,y,x,w,v,u,t,s,r,q
z=a.gE(a)
y=0
x=0
while(!0){if(!(y<80||x<3))break
if(!z.m())return
w=H.b(z.gq())
b.push(w)
y+=w.length+2;++x}if(!z.m()){if(x<=5)return
if(0>=b.length)return H.a(b,-1)
v=b.pop()
if(0>=b.length)return H.a(b,-1)
u=b.pop()}else{t=z.gq();++x
if(!z.m()){if(x<=4){b.push(H.b(t))
return}v=H.b(t)
if(0>=b.length)return H.a(b,-1)
u=b.pop()
y+=v.length+2}else{s=z.gq();++x
for(;z.m();t=s,s=r){r=z.gq();++x
if(x>100){while(!0){if(!(y>75&&x>3))break
if(0>=b.length)return H.a(b,-1)
y-=b.pop().length+2;--x}b.push("...")
return}}u=H.b(t)
v=H.b(s)
y+=v.length+u.length+4}}if(x>b.length+2){y+=5
q="..."}else q=null
while(!0){if(!(y>80&&b.length>3))break
if(0>=b.length)return H.a(b,-1)
y-=b.pop().length+2
if(q==null){y+=5
q="..."}}if(q!=null)b.push(q)
b.push(u)
b.push(v)},
a3:function(a,b,c,d){return new P.kz(0,null,null,null,null,null,0,[d])},
dW:function(a,b){var z,y,x
z=P.a3(null,null,null,b)
for(y=a.length,x=0;x<a.length;a.length===y||(0,H.A)(a),++x)z.C(0,a[x])
return z},
cL:function(a){var z,y,x
z={}
if(P.d5(a))return"{...}"
y=new P.aH("")
try{$.$get$bf().push(a)
x=y
x.sk(x.gk()+"{")
z.a=!0
a.K(0,new P.iG(z,y))
z=y
z.sk(z.gk()+"}")}finally{z=$.$get$bf()
if(0>=z.length)return H.a(z,-1)
z.pop()}z=y.gk()
return z.charCodeAt(0)==0?z:z},
eU:{"^":"a2;a,b,c,d,e,f,r,$ti",
ba:function(a){return H.m3(a)&0x3ffffff},
bb:function(a,b){var z,y,x
if(a==null)return-1
z=a.length
for(y=0;y<z;++y){x=a[y].gev()
if(x==null?b==null:x===b)return y}return-1},
w:{
bc:function(a,b){return new P.eU(0,null,null,null,null,null,0,[a,b])}}},
kz:{"^":"kr;a,b,c,d,e,f,r,$ti",
gE:function(a){var z=new P.bG(this,this.r,null,null)
z.c=this.e
return z},
gi:function(a){return this.a},
gD:function(a){return this.a===0},
gU:function(a){return this.a!==0},
L:function(a,b){var z,y
if(typeof b==="string"&&b!=="__proto__"){z=this.b
if(z==null)return!1
return z[b]!=null}else if(typeof b==="number"&&(b&0x3ffffff)===b){y=this.c
if(y==null)return!1
return y[b]!=null}else return this.fR(b)},
fR:function(a){var z=this.d
if(z==null)return!1
return this.bu(z[this.bt(a)],a)>=0},
cO:function(a){var z
if(!(typeof a==="string"&&a!=="__proto__"))z=typeof a==="number"&&(a&0x3ffffff)===a
else z=!0
if(z)return this.L(0,a)?a:null
else return this.ha(a)},
ha:function(a){var z,y,x
z=this.d
if(z==null)return
y=z[this.bt(a)]
x=this.bu(y,a)
if(x<0)return
return J.ag(y,x).gcg()},
C:function(a,b){var z,y,x
if(typeof b==="string"&&b!=="__proto__"){z=this.b
if(z==null){y=Object.create(null)
y["<non-identifier-key>"]=y
delete y["<non-identifier-key>"]
this.b=y
z=y}return this.dv(z,b)}else if(typeof b==="number"&&(b&0x3ffffff)===b){x=this.c
if(x==null){y=Object.create(null)
y["<non-identifier-key>"]=y
delete y["<non-identifier-key>"]
this.c=y
x=y}return this.dv(x,b)}else return this.aa(b)},
aa:function(a){var z,y,x
z=this.d
if(z==null){z=P.kB()
this.d=z}y=this.bt(a)
x=z[y]
if(x==null)z[y]=[this.ca(a)]
else{if(this.bu(x,a)>=0)return!1
x.push(this.ca(a))}return!0},
A:function(a,b){if(typeof b==="string"&&b!=="__proto__")return this.dA(this.b,b)
else if(typeof b==="number"&&(b&0x3ffffff)===b)return this.dA(this.c,b)
else return this.cu(b)},
cu:function(a){var z,y,x
z=this.d
if(z==null)return!1
y=z[this.bt(a)]
x=this.bu(y,a)
if(x<0)return!1
this.dB(y.splice(x,1)[0])
return!0},
a8:function(a){if(this.a>0){this.f=null
this.e=null
this.d=null
this.c=null
this.b=null
this.a=0
this.r=this.r+1&67108863}},
dv:function(a,b){if(a[b]!=null)return!1
a[b]=this.ca(b)
return!0},
dA:function(a,b){var z
if(a==null)return!1
z=a[b]
if(z==null)return!1
this.dB(z)
delete a[b]
return!0},
ca:function(a){var z,y
z=new P.kA(a,null,null)
if(this.e==null){this.f=z
this.e=z}else{y=this.f
z.c=y
y.b=z
this.f=z}++this.a
this.r=this.r+1&67108863
return z},
dB:function(a){var z,y
z=a.gdz()
y=a.gdw()
if(z==null)this.e=y
else z.b=y
if(y==null)this.f=z
else y.sdz(z);--this.a
this.r=this.r+1&67108863},
bt:function(a){return J.a0(a)&0x3ffffff},
bu:function(a,b){var z,y
if(a==null)return-1
z=a.length
for(y=0;y<z;++y)if(J.J(a[y].gcg(),b))return y
return-1},
$isi:1,
$asi:null,
w:{
kB:function(){var z=Object.create(null)
z["<non-identifier-key>"]=z
delete z["<non-identifier-key>"]
return z}}},
kA:{"^":"e;cg:a<,dw:b<,dz:c@"},
bG:{"^":"e;a,b,c,d",
gq:function(){return this.d},
m:function(){var z=this.a
if(this.b!==z.r)throw H.c(new P.a8(z))
else{z=this.c
if(z==null){this.d=null
return!1}else{this.d=z.gcg()
this.c=this.c.gdw()
return!0}}}},
kr:{"^":"jj;$ti"},
aQ:{"^":"iO;$ti"},
iO:{"^":"e+X;",$ash:null,$asi:null,$ish:1,$isi:1},
X:{"^":"e;$ti",
gE:function(a){return new H.bU(a,this.gi(a),0,null)},
J:function(a,b){return this.h(a,b)},
K:function(a,b){var z,y
z=this.gi(a)
for(y=0;y<z;++y){b.$1(this.h(a,y))
if(z!==this.gi(a))throw H.c(new P.a8(a))}},
gD:function(a){return this.gi(a)===0},
gU:function(a){return!this.gD(a)},
ag:function(a,b){return new H.b7(a,b,[H.I(a,"X",0),null])},
aC:function(a,b){var z,y,x
z=H.q([],[H.I(a,"X",0)])
C.a.si(z,this.gi(a))
for(y=0;y<this.gi(a);++y){x=this.h(a,y)
if(y>=z.length)return H.a(z,y)
z[y]=x}return z},
aM:function(a){return this.aC(a,!0)},
C:function(a,b){var z=this.gi(a)
this.si(a,z+1)
this.l(a,z,b)},
A:function(a,b){var z
for(z=0;z<this.gi(a);++z)if(J.J(this.h(a,z),b)){this.Z(a,z,this.gi(a)-1,a,z+1)
this.si(a,this.gi(a)-1)
return!0}return!1},
Z:["dg",function(a,b,c,d,e){var z,y,x,w,v
P.cP(b,c,this.gi(a),null,null,null)
z=c-b
if(z===0)return
if(H.bK(d,"$ish",[H.I(a,"X",0)],"$ash")){y=e
x=d}else{x=new H.cQ(d,e,null,[H.I(d,"X",0)]).aC(0,!1)
y=0}w=J.v(x)
if(y+z>w.gi(x))throw H.c(H.dR())
if(y<b)for(v=z-1;v>=0;--v)this.l(a,b+v,w.h(x,y+v))
else for(v=0;v<z;++v)this.l(a,b+v,w.h(x,y+v))}],
ah:function(a,b){var z=this.h(a,b)
this.Z(a,b,this.gi(a)-1,a,b+1)
this.si(a,this.gi(a)-1)
return z},
j:function(a){return P.bS(a,"[","]")},
$ish:1,
$ash:null,
$isi:1,
$asi:null},
l9:{"^":"e;",
l:function(a,b,c){throw H.c(new P.u("Cannot modify unmodifiable map"))},
A:function(a,b){throw H.c(new P.u("Cannot modify unmodifiable map"))},
$isG:1},
iE:{"^":"e;",
h:function(a,b){return this.a.h(0,b)},
l:function(a,b,c){this.a.l(0,b,c)},
N:function(a){return this.a.N(a)},
K:function(a,b){this.a.K(0,b)},
gD:function(a){var z=this.a
return z.gD(z)},
gU:function(a){var z=this.a
return z.gU(z)},
gi:function(a){var z=this.a
return z.gi(z)},
gM:function(){return this.a.gM()},
A:function(a,b){return this.a.A(0,b)},
j:function(a){return this.a.j(0)},
$isG:1},
eH:{"^":"iE+l9;$ti",$asG:null,$isG:1},
iG:{"^":"f:5;a,b",
$2:function(a,b){var z,y
z=this.a
if(!z.a)this.b.k+=", "
z.a=!1
z=this.b
y=z.k+=H.b(a)
z.k=y+": "
z.k+=H.b(b)}},
iD:{"^":"aG;a,b,c,d,$ti",
gE:function(a){return new P.kC(this,this.c,this.d,this.b,null)},
gD:function(a){return this.b===this.c},
gi:function(a){return(this.c-this.b&this.a.length-1)>>>0},
J:function(a,b){var z,y,x,w
z=(this.c-this.b&this.a.length-1)>>>0
if(typeof b!=="number")return H.l(b)
if(0>b||b>=z)H.B(P.aj(b,this,"index",null,z))
y=this.a
x=y.length
w=(this.b+b&x-1)>>>0
if(w<0||w>=x)return H.a(y,w)
return y[w]},
C:function(a,b){this.aa(b)},
A:function(a,b){var z,y
for(z=this.b;z!==this.c;z=(z+1&this.a.length-1)>>>0){y=this.a
if(z<0||z>=y.length)return H.a(y,z)
if(J.J(y[z],b)){this.cu(z);++this.d
return!0}}return!1},
a8:function(a){var z,y,x,w,v
z=this.b
y=this.c
if(z!==y){for(x=this.a,w=x.length,v=w-1;z!==y;z=(z+1&v)>>>0){if(z<0||z>=w)return H.a(x,z)
x[z]=null}this.c=0
this.b=0;++this.d}},
j:function(a){return P.bS(this,"{","}")},
eL:function(){var z,y,x,w
z=this.b
if(z===this.c)throw H.c(H.cE());++this.d
y=this.a
x=y.length
if(z>=x)return H.a(y,z)
w=y[z]
y[z]=null
this.b=(z+1&x-1)>>>0
return w},
aa:function(a){var z,y,x
z=this.a
y=this.c
x=z.length
if(y<0||y>=x)return H.a(z,y)
z[y]=a
x=(y+1&x-1)>>>0
this.c=x
if(this.b===x)this.dM();++this.d},
cu:function(a){var z,y,x,w,v,u,t,s
z=this.a
y=z.length
x=y-1
w=this.b
v=this.c
if((a-w&x)>>>0<(v-a&x)>>>0){for(u=a;u!==w;u=t){t=(u-1&x)>>>0
if(t<0||t>=y)return H.a(z,t)
v=z[t]
if(u<0||u>=y)return H.a(z,u)
z[u]=v}if(w>=y)return H.a(z,w)
z[w]=null
this.b=(w+1&x)>>>0
return(a+1&x)>>>0}else{w=(v-1&x)>>>0
this.c=w
for(u=a;u!==w;u=s){s=(u+1&x)>>>0
if(s<0||s>=y)return H.a(z,s)
v=z[s]
if(u<0||u>=y)return H.a(z,u)
z[u]=v}if(w<0||w>=y)return H.a(z,w)
z[w]=null
return a}},
dM:function(){var z,y,x,w
z=new Array(this.a.length*2)
z.fixed$length=Array
y=H.q(z,this.$ti)
z=this.a
x=this.b
w=z.length-x
C.a.Z(y,0,w,z,x)
C.a.Z(y,w,w+this.b,this.a,0)
this.b=0
this.c=this.a.length
this.a=y},
fA:function(a,b){var z=new Array(8)
z.fixed$length=Array
this.a=H.q(z,[b])},
$asi:null,
w:{
cK:function(a,b){var z=new P.iD(null,0,0,0,[b])
z.fA(a,b)
return z}}},
kC:{"^":"e;a,b,c,d,e",
gq:function(){return this.e},
m:function(){var z,y,x
z=this.a
if(this.c!==z.d)H.B(new P.a8(z))
y=this.d
if(y===this.b){this.e=null
return!1}z=z.a
x=z.length
if(y>=x)return H.a(z,y)
this.e=z[y]
this.d=(y+1&x-1)>>>0
return!0}},
jk:{"^":"e;$ti",
gD:function(a){return this.a===0},
gU:function(a){return this.a!==0},
W:function(a,b){var z
for(z=J.E(b);z.m();)this.C(0,z.gq())},
ag:function(a,b){return new H.cx(this,b,[H.F(this,0),null])},
j:function(a){return P.bS(this,"{","}")},
bN:function(a,b){var z,y
z=new P.bG(this,this.r,null,null)
z.c=this.e
if(!z.m())return""
if(b===""){y=""
do y+=H.b(z.d)
while(z.m())}else{y=H.b(z.d)
for(;z.m();)y=y+b+H.b(z.d)}return y.charCodeAt(0)==0?y:y},
J:function(a,b){var z,y,x
if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(P.dt("index"))
if(b<0)H.B(P.H(b,0,null,"index",null))
for(z=new P.bG(this,this.r,null,null),z.c=this.e,y=0;z.m();){x=z.d
if(b===y)return x;++y}throw H.c(P.aj(b,this,"index",null,y))},
$isi:1,
$asi:null},
jj:{"^":"jk;$ti"}}],["","",,P,{"^":"",
c8:function(a){var z
if(a==null)return
if(typeof a!="object")return a
if(Object.getPrototypeOf(a)!==Array.prototype)return new P.kt(a,Object.create(null),null)
for(z=0;z<a.length;++z)a[z]=P.c8(a[z])
return a},
ll:function(a,b){var z,y,x,w
if(typeof a!=="string")throw H.c(H.L(a))
z=null
try{z=JSON.parse(a)}catch(x){y=H.D(x)
w=String(y)
throw H.c(new P.bR(w,null,null))}w=P.c8(z)
return w},
o9:[function(a){return a.j1()},"$1","lz",2,0,0,9],
kt:{"^":"e;a,b,c",
h:function(a,b){var z,y
z=this.b
if(z==null)return this.c.h(0,b)
else if(typeof b!=="string")return
else{y=z[b]
return typeof y=="undefined"?this.hg(b):y}},
gi:function(a){var z
if(this.b==null){z=this.c
z=z.gi(z)}else z=this.ae().length
return z},
gD:function(a){var z
if(this.b==null){z=this.c
z=z.gi(z)}else z=this.ae().length
return z===0},
gU:function(a){var z
if(this.b==null){z=this.c
z=z.gi(z)}else z=this.ae().length
return z>0},
gM:function(){if(this.b==null)return this.c.gM()
return new P.ku(this)},
l:function(a,b,c){var z,y
if(this.b==null)this.c.l(0,b,c)
else if(this.N(b)){z=this.b
z[b]=c
y=this.a
if(y==null?z!=null:y!==z)y[b]=null}else this.e6().l(0,b,c)},
N:function(a){if(this.b==null)return this.c.N(a)
if(typeof a!=="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
A:function(a,b){if(this.b!=null&&!this.N(b))return
return this.e6().A(0,b)},
K:function(a,b){var z,y,x,w
if(this.b==null)return this.c.K(0,b)
z=this.ae()
for(y=0;y<z.length;++y){x=z[y]
w=this.b[x]
if(typeof w=="undefined"){w=P.c8(this.a[x])
this.b[x]=w}b.$2(x,w)
if(z!==this.c)throw H.c(new P.a8(this))}},
j:function(a){return P.cL(this)},
ae:function(){var z=this.c
if(z==null){z=Object.keys(this.a)
this.c=z}return z},
e6:function(){var z,y,x,w,v
if(this.b==null)return this.c
z=P.iC(P.p,null)
y=this.ae()
for(x=0;w=y.length,x<w;++x){v=y[x]
z.l(0,v,this.h(0,v))}if(w===0)y.push(null)
else C.a.si(y,0)
this.b=null
this.a=null
this.c=z
return z},
hg:function(a){var z
if(!Object.prototype.hasOwnProperty.call(this.a,a))return
z=P.c8(this.a[a])
return this.b[a]=z},
$isG:1,
$asG:function(){return[P.p,null]}},
ku:{"^":"aG;a",
gi:function(a){var z=this.a
if(z.b==null){z=z.c
z=z.gi(z)}else z=z.ae().length
return z},
J:function(a,b){var z=this.a
if(z.b==null)z=z.gM().J(0,b)
else{z=z.ae()
if(b>>>0!==b||b>=z.length)return H.a(z,b)
z=z[b]}return z},
gE:function(a){var z=this.a
if(z.b==null){z=z.gM()
z=z.gE(z)}else{z=z.ae()
z=new J.bo(z,z.length,0,null)}return z},
$asaG:function(){return[P.p]},
$asi:function(){return[P.p]},
$asQ:function(){return[P.p]}},
h8:{"^":"e;"},
dD:{"^":"e;"},
cI:{"^":"P;a,b",
j:function(a){if(this.b!=null)return"Converting object to an encodable object failed."
else return"Converting object did not return an encodable object."}},
iw:{"^":"cI;a,b",
j:function(a){return"Cyclic error in JSON stringify"}},
iv:{"^":"h8;a,b",
hV:function(a,b){var z=P.ll(a,this.ghW().a)
return z},
ek:function(a){return this.hV(a,null)},
i5:function(a,b){var z=this.gi6()
z=P.kw(a,z.b,z.a)
return z},
cJ:function(a){return this.i5(a,null)},
gi6:function(){return C.H},
ghW:function(){return C.G}},
iy:{"^":"dD;ew:a<,b"},
ix:{"^":"dD;a"},
kx:{"^":"e;",
eX:function(a){var z,y,x,w,v,u,t
z=J.v(a)
y=z.gi(a)
if(typeof y!=="number")return H.l(y)
x=this.c
w=0
v=0
for(;v<y;++v){u=z.cH(a,v)
if(u>92)continue
if(u<32){if(v>w)x.k+=z.am(a,w,v)
w=v+1
x.k+=H.a4(92)
switch(u){case 8:x.k+=H.a4(98)
break
case 9:x.k+=H.a4(116)
break
case 10:x.k+=H.a4(110)
break
case 12:x.k+=H.a4(102)
break
case 13:x.k+=H.a4(114)
break
default:x.k+=H.a4(117)
x.k+=H.a4(48)
x.k+=H.a4(48)
t=u>>>4&15
x.k+=H.a4(t<10?48+t:87+t)
t=u&15
x.k+=H.a4(t<10?48+t:87+t)
break}}else if(u===34||u===92){if(v>w)x.k+=z.am(a,w,v)
w=v+1
x.k+=H.a4(92)
x.k+=H.a4(u)}}if(w===0)x.k+=H.b(a)
else if(w<y)x.k+=z.am(a,w,y)},
c8:function(a){var z,y,x,w
for(z=this.a,y=z.length,x=0;x<y;++x){w=z[x]
if(a==null?w==null:a===w)throw H.c(new P.iw(a,null))}z.push(a)},
bU:function(a){var z,y,x,w
if(this.eW(a))return
this.c8(a)
try{z=this.b.$1(a)
if(!this.eW(z))throw H.c(new P.cI(a,null))
x=this.a
if(0>=x.length)return H.a(x,-1)
x.pop()}catch(w){y=H.D(w)
throw H.c(new P.cI(a,y))}},
eW:function(a){var z,y
if(typeof a==="number"){if(!isFinite(a))return!1
this.c.k+=C.d.j(a)
return!0}else if(a===!0){this.c.k+="true"
return!0}else if(a===!1){this.c.k+="false"
return!0}else if(a==null){this.c.k+="null"
return!0}else if(typeof a==="string"){z=this.c
z.k+='"'
this.eX(a)
z.k+='"'
return!0}else{z=J.j(a)
if(!!z.$ish){this.c8(a)
this.iR(a)
z=this.a
if(0>=z.length)return H.a(z,-1)
z.pop()
return!0}else if(!!z.$isG){this.c8(a)
y=this.iS(a)
z=this.a
if(0>=z.length)return H.a(z,-1)
z.pop()
return y}else return!1}},
iR:function(a){var z,y,x
z=this.c
z.k+="["
y=J.v(a)
if(y.gi(a)>0){this.bU(y.h(a,0))
for(x=1;x<y.gi(a);++x){z.k+=","
this.bU(y.h(a,x))}}z.k+="]"},
iS:function(a){var z,y,x,w,v,u,t
z={}
if(a.gD(a)){this.c.k+="{}"
return!0}y=a.gi(a)*2
x=new Array(y)
z.a=0
z.b=!0
a.K(0,new P.ky(z,x))
if(!z.b)return!1
w=this.c
w.k+="{"
for(v='"',u=0;u<y;u+=2,v=',"'){w.k+=v
this.eX(x[u])
w.k+='":'
t=u+1
if(t>=y)return H.a(x,t)
this.bU(x[t])}w.k+="}"
return!0}},
ky:{"^":"f:5;a,b",
$2:function(a,b){var z,y,x,w,v
if(typeof a!=="string")this.a.b=!1
z=this.b
y=this.a
x=y.a
w=x+1
y.a=w
v=z.length
if(x>=v)return H.a(z,x)
z[x]=a
y.a=w+1
if(w>=v)return H.a(z,w)
z[w]=b}},
kv:{"^":"kx;c,a,b",w:{
kw:function(a,b,c){var z,y,x
z=new P.aH("")
y=new P.kv(z,[],P.lz())
y.bU(a)
x=z.k
return x.charCodeAt(0)==0?x:x}}}}],["","",,P,{"^":"",
bs:function(a){if(typeof a==="number"||typeof a==="boolean"||null==a)return J.C(a)
if(typeof a==="string")return JSON.stringify(a)
return P.hs(a)},
hs:function(a){var z=J.j(a)
if(!!z.$isf)return z.j(a)
return H.c_(a)},
bQ:function(a){return new P.kd(a)},
av:function(a,b,c){var z,y
z=H.q([],[c])
for(y=J.E(a);y.m();)z.push(y.gq())
if(b)return z
z.fixed$length=Array
return z},
fm:function(a,b){var z,y
z=J.cn(a)
y=H.ee(z,null,P.lB())
if(y!=null)return y
y=H.j5(z,P.lA())
if(y!=null)return y
if(b==null)throw H.c(new P.bR(a,null,null))
return b.$1(a)},
oh:[function(a){return},"$1","lB",2,0,20],
og:[function(a){return},"$1","lA",2,0,21],
cg:function(a){H.m4(H.b(a))},
je:function(a,b,c){return new H.io(a,H.dV(a,!1,!0,!1),null,null)},
iL:{"^":"f:15;a,b",
$2:function(a,b){var z,y,x
z=this.b
y=this.a
z.k+=y.a
x=z.k+=H.b(a.ghb())
z.k=x+": "
z.k+=H.b(P.bs(b))
y.a=", "}},
bI:{"^":"e;"},
"+bool":0,
b4:{"^":"e;a,b",
G:function(a,b){if(b==null)return!1
if(!(b instanceof P.b4))return!1
return this.a===b.a&&this.b===b.b},
gI:function(a){var z=this.a
return(z^C.d.cz(z,30))&1073741823},
j:function(a){var z,y,x,w,v,u,t
z=P.hh(H.j4(this))
y=P.br(H.j2(this))
x=P.br(H.iZ(this))
w=P.br(H.j_(this))
v=P.br(H.j1(this))
u=P.br(H.j3(this))
t=P.hi(H.j0(this))
if(this.b)return z+"-"+y+"-"+x+" "+w+":"+v+":"+u+"."+t+"Z"
else return z+"-"+y+"-"+x+" "+w+":"+v+":"+u+"."+t},
C:function(a,b){return P.hg(C.d.v(this.a,b.gj0()),this.b)},
giA:function(){return this.a},
di:function(a,b){var z
if(!(Math.abs(this.a)>864e13))z=!1
else z=!0
if(z)throw H.c(P.aB(this.giA()))},
w:{
hg:function(a,b){var z=new P.b4(a,b)
z.di(a,b)
return z},
hh:function(a){var z,y
z=Math.abs(a)
y=a<0?"-":""
if(z>=1000)return""+a
if(z>=100)return y+"0"+H.b(z)
if(z>=10)return y+"00"+H.b(z)
return y+"000"+H.b(z)},
hi:function(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
br:function(a){if(a>=10)return""+a
return"0"+a}}},
ap:{"^":"bi;"},
"+double":0,
aE:{"^":"e;aT:a<",
v:function(a,b){return new P.aE(this.a+b.gaT())},
V:function(a,b){return new P.aE(this.a-b.gaT())},
H:function(a,b){if(typeof b!=="number")return H.l(b)
return new P.aE(C.d.aB(this.a*b))},
c4:function(a,b){if(b===0)throw H.c(new P.hV())
return new P.aE(C.f.c4(this.a,b))},
ak:function(a,b){return this.a<b.gaT()},
bX:function(a,b){return this.a>b.gaT()},
bV:function(a,b){return C.f.bV(this.a,b.gaT())},
G:function(a,b){if(b==null)return!1
if(!(b instanceof P.aE))return!1
return this.a===b.a},
gI:function(a){return this.a&0x1FFFFFFF},
j:function(a){var z,y,x,w,v
z=new P.ho()
y=this.a
if(y<0)return"-"+new P.aE(0-y).j(0)
x=z.$1(C.f.bF(y,6e7)%60)
w=z.$1(C.f.bF(y,1e6)%60)
v=new P.hn().$1(y%1e6)
return""+C.f.bF(y,36e8)+":"+H.b(x)+":"+H.b(w)+"."+H.b(v)},
e8:function(a){return new P.aE(Math.abs(this.a))}},
hn:{"^":"f:6;",
$1:function(a){if(a>=1e5)return""+a
if(a>=1e4)return"0"+a
if(a>=1000)return"00"+a
if(a>=100)return"000"+a
if(a>=10)return"0000"+a
return"00000"+a}},
ho:{"^":"f:6;",
$1:function(a){if(a>=10)return""+a
return"0"+a}},
P:{"^":"e;",
gal:function(){return H.a_(this.$thrownJsError)}},
e5:{"^":"P;",
j:function(a){return"Throw of null."}},
as:{"^":"P;a,b,c,d",
gcj:function(){return"Invalid argument"+(!this.a?"(s)":"")},
gci:function(){return""},
j:function(a){var z,y,x,w,v,u
z=this.c
y=z!=null?" ("+z+")":""
z=this.d
x=z==null?"":": "+H.b(z)
w=this.gcj()+y+x
if(!this.a)return w
v=this.gci()
u=P.bs(this.b)
return w+v+": "+H.b(u)},
w:{
aB:function(a){return new P.as(!1,null,null,a)},
co:function(a,b,c){return new P.as(!0,a,b,c)},
dt:function(a){return new P.as(!1,null,a,"Must not be null")}}},
eg:{"^":"as;e,f,a,b,c,d",
gcj:function(){return"RangeError"},
gci:function(){var z,y,x
z=this.e
if(z==null){z=this.f
y=z!=null?": Not less than or equal to "+H.b(z):""}else{x=this.f
if(x==null)y=": Not greater than or equal to "+H.b(z)
else if(x>z)y=": Not in range "+H.b(z)+".."+H.b(x)+", inclusive"
else y=x<z?": Valid value range is empty":": Only valid value is "+H.b(z)}return y},
w:{
ba:function(a,b,c){return new P.eg(null,null,!0,a,b,"Value not in range")},
H:function(a,b,c,d,e){return new P.eg(b,c,!0,a,d,"Invalid value")},
cP:function(a,b,c,d,e,f){if(0>a||a>c)throw H.c(P.H(a,0,c,"start",f))
if(a>b||b>c)throw H.c(P.H(b,a,c,"end",f))
return b}}},
hS:{"^":"as;e,i:f>,a,b,c,d",
gcj:function(){return"RangeError"},
gci:function(){if(J.b0(this.b,0))return": index must not be negative"
var z=this.f
if(z===0)return": no indices are valid"
return": index should be less than "+H.b(z)},
w:{
aj:function(a,b,c,d,e){var z=e!=null?e:J.a1(b)
return new P.hS(b,z,!0,a,c,"Index out of range")}}},
iK:{"^":"P;a,b,c,d,e",
j:function(a){var z,y,x,w,v,u,t,s
z={}
y=new P.aH("")
z.a=""
for(x=this.c,w=x.length,v=0;v<w;++v){u=x[v]
y.k+=z.a
y.k+=H.b(P.bs(u))
z.a=", "}this.d.K(0,new P.iL(z,y))
t=P.bs(this.a)
s=y.j(0)
x="NoSuchMethodError: method not found: '"+H.b(this.b.a)+"'\nReceiver: "+H.b(t)+"\nArguments: ["+s+"]"
return x},
w:{
e1:function(a,b,c,d,e){return new P.iK(a,b,c,d,e)}}},
u:{"^":"P;a",
j:function(a){return"Unsupported operation: "+this.a}},
cT:{"^":"P;a",
j:function(a){var z=this.a
return z!=null?"UnimplementedError: "+H.b(z):"UnimplementedError"}},
a5:{"^":"P;a",
j:function(a){return"Bad state: "+this.a}},
a8:{"^":"P;a",
j:function(a){var z=this.a
if(z==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+H.b(P.bs(z))+"."}},
iP:{"^":"e;",
j:function(a){return"Out of Memory"},
gal:function(){return},
$isP:1},
em:{"^":"e;",
j:function(a){return"Stack Overflow"},
gal:function(){return},
$isP:1},
hf:{"^":"P;a",
j:function(a){var z=this.a
return z==null?"Reading static variable during its initialization":"Reading static variable '"+H.b(z)+"' during its initialization"}},
kd:{"^":"e;a",
j:function(a){var z=this.a
if(z==null)return"Exception"
return"Exception: "+H.b(z)},
$isbP:1},
bR:{"^":"e;a,b,bP:c>",
j:function(a){var z,y,x
z=this.a
y=z!=null&&""!==z?"FormatException: "+H.b(z):"FormatException"
x=this.b
if(typeof x!=="string")return y
if(x.length>78)x=C.e.am(x,0,75)+"..."
return y+"\n"+x},
$isbP:1},
hV:{"^":"e;",
j:function(a){return"IntegerDivisionByZeroException"},
$isbP:1},
ht:{"^":"e;a,dS",
j:function(a){return"Expando:"+H.b(this.a)},
h:function(a,b){var z,y
z=this.dS
if(typeof z!=="string"){if(b==null||typeof b==="boolean"||typeof b==="number"||typeof b==="string")H.B(P.co(b,"Expandos are not allowed on strings, numbers, booleans or null",null))
return z.get(b)}y=H.cO(b,"expando$values")
return y==null?null:H.cO(y,z)},
l:function(a,b,c){var z,y
z=this.dS
if(typeof z!=="string")z.set(b,c)
else{y=H.cO(b,"expando$values")
if(y==null){y=new P.e()
H.ef(b,"expando$values",y)}H.ef(y,z,c)}}},
y:{"^":"bi;"},
"+int":0,
Q:{"^":"e;$ti",
ag:function(a,b){return H.bW(this,b,H.I(this,"Q",0),null)},
d8:["fj",function(a,b){return new H.cU(this,b,[H.I(this,"Q",0)])}],
aC:function(a,b){return P.av(this,!0,H.I(this,"Q",0))},
aM:function(a){return this.aC(a,!0)},
gi:function(a){var z,y
z=this.gE(this)
for(y=0;z.m();)++y
return y},
gD:function(a){return!this.gE(this).m()},
gU:function(a){return!this.gD(this)},
gaD:function(a){var z,y
z=this.gE(this)
if(!z.m())throw H.c(H.cE())
y=z.gq()
if(z.m())throw H.c(H.ig())
return y},
J:function(a,b){var z,y,x
if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(P.dt("index"))
if(b<0)H.B(P.H(b,0,null,"index",null))
for(z=this.gE(this),y=0;z.m();){x=z.gq()
if(b===y)return x;++y}throw H.c(P.aj(b,this,"index",null,y))},
j:function(a){return P.ie(this,"(",")")}},
bT:{"^":"e;"},
h:{"^":"e;$ti",$ash:null,$isi:1,$asi:null},
"+List":0,
b8:{"^":"e;",
gI:function(a){return P.e.prototype.gI.call(this,this)},
j:function(a){return"null"}},
"+Null":0,
bi:{"^":"e;"},
"+num":0,
e:{"^":";",
G:function(a,b){return this===b},
gI:function(a){return H.ax(this)},
j:["fn",function(a){return H.c_(this)}],
cS:function(a,b){throw H.c(P.e1(this,b.geB(),b.geI(),b.geC(),null))},
toString:function(){return this.j(this)}},
bB:{"^":"e;"},
p:{"^":"e;"},
"+String":0,
aH:{"^":"e;k@",
gi:function(a){return this.k.length},
gU:function(a){return this.k.length!==0},
j:function(a){var z=this.k
return z.charCodeAt(0)==0?z:z},
w:{
eo:function(a,b,c){var z=J.E(b)
if(!z.m())return a
if(c.length===0){do a+=H.b(z.gq())
while(z.m())}else{a+=H.b(z.gq())
for(;z.m();)a=a+c+H.b(z.gq())}return a}}},
bC:{"^":"e;"}}],["","",,W,{"^":"",
mb:function(){return window},
ds:function(a){var z=document.createElement("a")
if(a!=null)z.href=a
return z},
he:function(a){return a.replace(/^-ms-/,"ms-").replace(/-([\da-z])/ig,function(b,c){return c.toUpperCase()})},
hr:function(a,b,c){var z,y
z=document.body
y=(z&&C.n).a1(z,a,b,c)
y.toString
z=new H.cU(new W.aa(y),new W.lx(),[W.t])
return z.gaD(z)},
b5:function(a){var z,y,x,w
z="element tag unavailable"
try{y=J.m(a)
x=y.geO(a)
if(typeof x==="string")z=y.geO(a)}catch(w){H.D(w)}return z},
hT:function(a){var z,y,x
y=document.createElement("input")
z=y
try{J.fR(z,a)}catch(x){H.D(x)}return z},
aJ:function(a,b){a=536870911&a+b
a=536870911&a+((524287&a)<<10)
return a^a>>>6},
eS:function(a){a=536870911&a+((67108863&a)<<3)
a^=a>>>11
return 536870911&a+((16383&a)<<15)},
f_:function(a){var z
if(a==null)return
if("postMessage" in a){z=W.k2(a)
if(!!J.j(z).$isW)return z
return}else return a},
fb:function(a){var z=$.x
if(z===C.c)return a
return z.hN(a,!0)},
w:{"^":"N;","%":"HTMLBRElement|HTMLContentElement|HTMLDListElement|HTMLDataListElement|HTMLDetailsElement|HTMLDialogElement|HTMLDirectoryElement|HTMLFontElement|HTMLFrameElement|HTMLHRElement|HTMLHeadElement|HTMLHeadingElement|HTMLHtmlElement|HTMLLabelElement|HTMLLegendElement|HTMLMarqueeElement|HTMLModElement|HTMLOptGroupElement|HTMLParagraphElement|HTMLPictureElement|HTMLPreElement|HTMLQuoteElement|HTMLShadowElement|HTMLSpanElement|HTMLTableCaptionElement|HTMLTableCellElement|HTMLTableColElement|HTMLTableDataCellElement|HTMLTableHeaderCellElement|HTMLTitleElement|HTMLTrackElement|HTMLUListElement|HTMLUnknownElement;HTMLElement"},
fW:{"^":"w;P:type},bM:href}",
j:function(a){return String(a)},
$isk:1,
"%":"HTMLAnchorElement"},
me:{"^":"w;bM:href}",
j:function(a){return String(a)},
$isk:1,
"%":"HTMLAreaElement"},
mf:{"^":"w;bM:href}","%":"HTMLBaseElement"},
cq:{"^":"k;",$iscq:1,"%":"Blob|File"},
cr:{"^":"w;",$iscr:1,$isW:1,$isk:1,"%":"HTMLBodyElement"},
mg:{"^":"w;R:name=,P:type},F:value%","%":"HTMLButtonElement"},
mh:{"^":"w;p:height%,n:width%",
f_:function(a,b,c){return a.getContext(b)},
da:function(a,b){return this.f_(a,b,null)},
"%":"HTMLCanvasElement"},
mi:{"^":"k;aw:fillStyle},aK:font},f0:globalAlpha},iy:lineJoin},cN:lineWidth},c2:strokeStyle},d3:textAlign},d4:textBaseline}",
aI:function(a){return a.beginPath()},
hQ:function(a,b,c,d,e){return a.clearRect(b,c,d,e)},
en:function(a,b,c,d,e){return a.fillRect(b,c,d,e)},
cP:function(a,b){return a.measureText(b)},
a4:function(a){return a.restore()},
a0:function(a){return a.save()},
iU:function(a,b){return a.stroke(b)},
c1:function(a){return a.stroke()},
ed:function(a,b,c,d,e,f,g){return a.bezierCurveTo(b,c,d,e,f,g)},
cG:function(a){return a.closePath()},
B:function(a,b,c){return a.lineTo(b,c)},
bf:function(a,b,c){return a.moveTo(b,c)},
S:function(a,b,c,d,e){return a.quadraticCurveTo(b,c,d,e)},
i9:function(a,b,c,d,e){a.fillText(b,c,d)},
cL:function(a,b,c,d){return this.i9(a,b,c,d,null)},
i8:function(a,b){a.fill(b)},
cK:function(a){return this.i8(a,"nonzero")},
"%":"CanvasRenderingContext2D"},
mj:{"^":"t;i:length=",$isk:1,"%":"CDATASection|CharacterData|Comment|ProcessingInstruction|Text"},
mk:{"^":"hW;i:length=",
dc:function(a,b){var z=this.h1(a,b)
return z!=null?z:""},
h1:function(a,b){if(W.he(b) in a)return a.getPropertyValue(b)
else return a.getPropertyValue(P.hj()+b)},
gp:function(a){return a.height},
gn:function(a){return a.width},
"%":"CSS2Properties|CSSStyleDeclaration|MSStyleCSSProperties"},
hW:{"^":"k+hd;"},
hd:{"^":"e;",
gp:function(a){return this.dc(a,"height")},
gn:function(a){return this.dc(a,"width")}},
hk:{"^":"w;","%":"HTMLDivElement"},
hl:{"^":"t;",$isk:1,"%":";DocumentFragment"},
ml:{"^":"k;",
j:function(a){return String(a)},
"%":"DOMException"},
hm:{"^":"k;",
j:function(a){return"Rectangle ("+H.b(a.left)+", "+H.b(a.top)+") "+H.b(this.gn(a))+" x "+H.b(this.gp(a))},
G:function(a,b){var z
if(b==null)return!1
z=J.j(b)
if(!z.$isay)return!1
return a.left===z.gbd(b)&&a.top===z.gbj(b)&&this.gn(a)===z.gn(b)&&this.gp(a)===z.gp(b)},
gI:function(a){var z,y,x,w
z=a.left
y=a.top
x=this.gn(a)
w=this.gp(a)
return W.eS(W.aJ(W.aJ(W.aJ(W.aJ(0,z&0x1FFFFFFF),y&0x1FFFFFFF),x&0x1FFFFFFF),w&0x1FFFFFFF))},
gd6:function(a){return new P.al(a.left,a.top,[null])},
gcE:function(a){return a.bottom},
gp:function(a){return a.height},
gbd:function(a){return a.left},
gd_:function(a){return a.right},
gbj:function(a){return a.top},
gn:function(a){return a.width},
gt:function(a){return a.x},
gu:function(a){return a.y},
$isay:1,
$asay:I.R,
"%":";DOMRectReadOnly"},
mm:{"^":"k;i:length=",
C:function(a,b){return a.add(b)},
A:function(a,b){return a.remove(b)},
"%":"DOMTokenList"},
jY:{"^":"aQ;cl:a<,b",
gD:function(a){return this.a.firstElementChild==null},
gi:function(a){return this.b.length},
h:function(a,b){var z=this.b
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]},
l:function(a,b,c){var z=this.b
if(b>>>0!==b||b>=z.length)return H.a(z,b)
this.a.replaceChild(c,z[b])},
si:function(a,b){throw H.c(new P.u("Cannot resize element lists"))},
C:function(a,b){this.a.appendChild(b)
return b},
gE:function(a){var z=this.aM(this)
return new J.bo(z,z.length,0,null)},
Z:function(a,b,c,d,e){throw H.c(new P.cT(null))},
A:function(a,b){return!1},
a8:function(a){J.di(this.a)},
ah:function(a,b){var z,y
z=this.b
if(b>=z.length)return H.a(z,b)
y=z[b]
this.a.removeChild(y)
return y},
$asaQ:function(){return[W.N]},
$ash:function(){return[W.N]},
$asi:function(){return[W.N]}},
af:{"^":"aQ;a,$ti",
gi:function(a){return this.a.length},
h:function(a,b){var z=this.a
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]},
l:function(a,b,c){throw H.c(new P.u("Cannot modify list"))},
si:function(a,b){throw H.c(new P.u("Cannot modify list"))},
gcF:function(a){return W.kJ(this)},
$ish:1,
$ash:null,
$isi:1,
$asi:null},
N:{"^":"t;hP:className},dT:namespaceURI=,eO:tagName=",
ghL:function(a){return new W.k7(a)},
gei:function(a){return new W.jY(a,a.children)},
gcF:function(a){return new W.k8(a)},
gbP:function(a){return P.jc(C.d.aB(a.offsetLeft),C.d.aB(a.offsetTop),C.d.aB(a.offsetWidth),C.d.aB(a.offsetHeight),null)},
j:function(a){return a.localName},
az:function(a,b,c,d,e){var z,y
z=this.a1(a,c,d,e)
switch(b.toLowerCase()){case"beforebegin":a.parentNode.insertBefore(z,a)
break
case"afterbegin":y=a.childNodes
a.insertBefore(z,y.length>0?y[0]:null)
break
case"beforeend":a.appendChild(z)
break
case"afterend":a.parentNode.insertBefore(z,a.nextSibling)
break
default:H.B(P.aB("Invalid position "+b))}},
a1:["c3",function(a,b,c,d){var z,y,x,w,v
if(c==null){z=$.dL
if(z==null){z=H.q([],[W.e2])
y=new W.e3(z)
z.push(W.eQ(null))
z.push(W.eW())
$.dL=y
d=y}else d=z
z=$.dK
if(z==null){z=new W.eX(d)
$.dK=z
c=z}else{z.a=d
c=z}}if($.at==null){z=document
y=z.implementation.createHTMLDocument("")
$.at=y
$.cy=y.createRange()
y=$.at
y.toString
x=y.createElement("base")
J.fQ(x,z.baseURI)
$.at.head.appendChild(x)}z=$.at
if(z.body==null){z.toString
y=z.createElement("body")
z.body=y}z=$.at
if(!!this.$iscr)w=z.body
else{y=a.tagName
z.toString
w=z.createElement(y)
$.at.body.appendChild(w)}if("createContextualFragment" in window.Range.prototype&&!C.a.L(C.J,a.tagName)){$.cy.selectNodeContents(w)
v=$.cy.createContextualFragment(b)}else{w.innerHTML=b
v=$.at.createDocumentFragment()
for(;z=w.firstChild,z!=null;)v.appendChild(z)}z=$.at.body
if(w==null?z!=null:w!==z)J.bm(w)
c.dd(v)
document.adoptNode(v)
return v},function(a,b,c){return this.a1(a,b,c,null)},"hU",null,null,"gj_",2,5,null,1,1],
sex:function(a,b){this.ac(a,b)},
c_:function(a,b,c,d){a.textContent=null
a.appendChild(this.a1(a,b,c,d))},
ac:function(a,b){return this.c_(a,b,null,null)},
eo:function(a){return a.focus()},
d9:function(a){return a.getBoundingClientRect()},
gbQ:function(a){return new W.an(a,"change",!1,[W.ac])},
gcT:function(a){return new W.an(a,"input",!1,[W.ac])},
geD:function(a){return new W.an(a,"mousedown",!1,[W.U])},
geE:function(a){return new W.an(a,"mousemove",!1,[W.U])},
geF:function(a){return new W.an(a,"mouseup",!1,[W.U])},
$isN:1,
$ist:1,
$ise:1,
$isk:1,
$isW:1,
"%":";Element"},
lx:{"^":"f:0;",
$1:function(a){return!!J.j(a).$isN}},
mn:{"^":"w;p:height%,R:name=,P:type},n:width%","%":"HTMLEmbedElement"},
mo:{"^":"ac;av:error=","%":"ErrorEvent"},
ac:{"^":"k;",
cX:function(a){return a.preventDefault()},
c0:function(a){return a.stopPropagation()},
$isac:1,
"%":"AnimationEvent|AnimationPlayerEvent|ApplicationCacheErrorEvent|AudioProcessingEvent|AutocompleteErrorEvent|BeforeInstallPromptEvent|BeforeUnloadEvent|BlobEvent|ClipboardEvent|CloseEvent|CustomEvent|DeviceLightEvent|DeviceMotionEvent|DeviceOrientationEvent|FontFaceSetLoadEvent|GamepadEvent|GeofencingEvent|HashChangeEvent|IDBVersionChangeEvent|MIDIConnectionEvent|MIDIMessageEvent|MediaEncryptedEvent|MediaKeyMessageEvent|MediaQueryListEvent|MediaStreamEvent|MediaStreamTrackEvent|MessageEvent|OfflineAudioCompletionEvent|PageTransitionEvent|PopStateEvent|PresentationConnectionAvailableEvent|PresentationConnectionCloseEvent|ProgressEvent|PromiseRejectionEvent|RTCDTMFToneChangeEvent|RTCDataChannelEvent|RTCIceCandidateEvent|RTCPeerConnectionIceEvent|RelatedEvent|ResourceProgressEvent|SecurityPolicyViolationEvent|ServiceWorkerMessageEvent|SpeechRecognitionEvent|SpeechSynthesisEvent|StorageEvent|TrackEvent|TransitionEvent|USBConnectionEvent|WebGLContextEvent|WebKitTransitionEvent;Event|InputEvent"},
W:{"^":"k;",
e9:function(a,b,c,d){if(c!=null)this.fK(a,b,c,!1)},
eK:function(a,b,c,d){if(c!=null)this.hm(a,b,c,!1)},
fK:function(a,b,c,d){return a.addEventListener(b,H.aY(c,1),!1)},
hm:function(a,b,c,d){return a.removeEventListener(b,H.aY(c,1),!1)},
$isW:1,
"%":"MessagePort;EventTarget"},
hM:{"^":"ac;","%":"ExtendableMessageEvent|FetchEvent|InstallEvent|PushEvent|ServicePortConnectEvent|SyncEvent;ExtendableEvent"},
mH:{"^":"w;R:name=","%":"HTMLFieldSetElement"},
mK:{"^":"w;cC:action=,i:length=,R:name=","%":"HTMLFormElement"},
mL:{"^":"i1;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.aj(b,a,null,null,null))
return a[b]},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
J:function(a,b){if(b>>>0!==b||b>=a.length)return H.a(a,b)
return a[b]},
$ish:1,
$ash:function(){return[W.t]},
$isi:1,
$asi:function(){return[W.t]},
$isZ:1,
$asZ:function(){return[W.t]},
$isT:1,
$asT:function(){return[W.t]},
"%":"HTMLCollection|HTMLFormControlsCollection|HTMLOptionsCollection"},
hX:{"^":"k+X;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
i1:{"^":"hX+bu;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
mM:{"^":"w;p:height%,R:name=,n:width%","%":"HTMLIFrameElement"},
cD:{"^":"k;p:height=,n:width=",$iscD:1,"%":"ImageData"},
mN:{"^":"w;p:height%,n:width%","%":"HTMLImageElement"},
mP:{"^":"w;p:height%,R:name=,fe:step},P:type},F:value%,n:width%",$isN:1,$isk:1,$isW:1,$ist:1,"%":"HTMLInputElement"},
mY:{"^":"w;R:name=","%":"HTMLKeygenElement"},
mZ:{"^":"w;F:value%","%":"HTMLLIElement"},
n0:{"^":"w;bM:href},P:type}","%":"HTMLLinkElement"},
n1:{"^":"k;",
j:function(a){return String(a)},
"%":"Location"},
n2:{"^":"w;R:name=","%":"HTMLMapElement"},
iH:{"^":"w;av:error=","%":"HTMLAudioElement;HTMLMediaElement"},
n5:{"^":"W;",
at:function(a){return a.clone()},
"%":"MediaStream"},
n6:{"^":"w;P:type}","%":"HTMLMenuElement"},
n7:{"^":"w;P:type}","%":"HTMLMenuItemElement"},
n8:{"^":"w;R:name=","%":"HTMLMetaElement"},
n9:{"^":"w;F:value%","%":"HTMLMeterElement"},
na:{"^":"iI;",
iT:function(a,b,c){return a.send(b,c)},
bZ:function(a,b){return a.send(b)},
"%":"MIDIOutput"},
iI:{"^":"W;","%":"MIDIInput;MIDIPort"},
U:{"^":"jJ;",
gbP:function(a){var z,y,x
if(!!a.offsetX)return new P.al(a.offsetX,a.offsetY,[null])
else{if(!J.j(W.f_(a.target)).$isN)throw H.c(new P.u("offsetX is only supported on elements"))
z=W.f_(a.target)
y=[null]
x=new P.al(a.clientX,a.clientY,y).V(0,J.fE(J.fF(z)))
return new P.al(J.dr(x.a),J.dr(x.b),y)}},
"%":"WheelEvent;DragEvent|MouseEvent"},
nl:{"^":"k;",$isk:1,"%":"Navigator"},
aa:{"^":"aQ;a",
gaD:function(a){var z,y
z=this.a
y=z.childNodes.length
if(y===0)throw H.c(new P.a5("No elements"))
if(y>1)throw H.c(new P.a5("More than one element"))
return z.firstChild},
C:function(a,b){this.a.appendChild(b)},
W:function(a,b){var z,y,x,w
z=b.a
y=this.a
if(z!==y)for(x=z.childNodes.length,w=0;w<x;++w)y.appendChild(z.firstChild)
return},
ah:function(a,b){var z,y,x
z=this.a
y=z.childNodes
if(b>=y.length)return H.a(y,b)
x=y[b]
z.removeChild(x)
return x},
A:function(a,b){return!1},
l:function(a,b,c){var z,y
z=this.a
y=z.childNodes
if(b>>>0!==b||b>=y.length)return H.a(y,b)
z.replaceChild(c,y[b])},
gE:function(a){var z=this.a.childNodes
return new W.dO(z,z.length,-1,null)},
Z:function(a,b,c,d,e){throw H.c(new P.u("Cannot setRange on Node list"))},
gi:function(a){return this.a.childNodes.length},
si:function(a,b){throw H.c(new P.u("Cannot set length on immutable List."))},
h:function(a,b){var z=this.a.childNodes
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]},
$asaQ:function(){return[W.t]},
$ash:function(){return[W.t]},
$asi:function(){return[W.t]}},
t:{"^":"W;cU:parentNode=,iE:previousSibling=",
giD:function(a){return new W.aa(a)},
a3:function(a){var z=a.parentNode
if(z!=null)z.removeChild(a)},
iL:function(a,b){var z,y
try{z=a.parentNode
J.ft(z,b,a)}catch(y){H.D(y)}return a},
fO:function(a){var z
for(;z=a.firstChild,z!=null;)a.removeChild(z)},
j:function(a){var z=a.nodeValue
return z==null?this.fi(a):z},
b4:function(a,b){return a.cloneNode(b)},
hn:function(a,b,c){return a.replaceChild(b,c)},
$ist:1,
$ise:1,
"%":"Document|HTMLDocument|XMLDocument;Node"},
nm:{"^":"i2;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.aj(b,a,null,null,null))
return a[b]},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
J:function(a,b){if(b>>>0!==b||b>=a.length)return H.a(a,b)
return a[b]},
$ish:1,
$ash:function(){return[W.t]},
$isi:1,
$asi:function(){return[W.t]},
$isZ:1,
$asZ:function(){return[W.t]},
$isT:1,
$asT:function(){return[W.t]},
"%":"NodeList|RadioNodeList"},
hY:{"^":"k+X;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
i2:{"^":"hY+bu;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
nn:{"^":"hM;cC:action=","%":"NotificationEvent"},
np:{"^":"w;P:type}","%":"HTMLOListElement"},
nq:{"^":"w;p:height%,R:name=,P:type},n:width%","%":"HTMLObjectElement"},
nr:{"^":"w;F:value%","%":"HTMLOptionElement"},
ns:{"^":"w;R:name=,F:value%","%":"HTMLOutputElement"},
nt:{"^":"w;R:name=,F:value%","%":"HTMLParamElement"},
nv:{"^":"U;p:height=,n:width=","%":"PointerEvent"},
nw:{"^":"w;F:value%","%":"HTMLProgressElement"},
nx:{"^":"k;",
d9:function(a){return a.getBoundingClientRect()},
"%":"Range"},
nA:{"^":"w;P:type}","%":"HTMLScriptElement"},
nB:{"^":"w;i:length=,R:name=,F:value%","%":"HTMLSelectElement"},
nC:{"^":"hl;",
b4:function(a,b){return a.cloneNode(b)},
at:function(a){return a.cloneNode()},
"%":"ShadowRoot"},
nD:{"^":"w;R:name=","%":"HTMLSlotElement"},
nE:{"^":"w;P:type}","%":"HTMLSourceElement"},
nF:{"^":"ac;av:error=","%":"SpeechRecognitionError"},
nG:{"^":"w;P:type}","%":"HTMLStyleElement"},
jt:{"^":"w;",
a1:function(a,b,c,d){var z,y
if("createContextualFragment" in window.Range.prototype)return this.c3(a,b,c,d)
z=W.hr("<table>"+H.b(b)+"</table>",c,d)
y=document.createDocumentFragment()
y.toString
new W.aa(y).W(0,J.fC(z))
return y},
"%":"HTMLTableElement"},
nK:{"^":"w;",
a1:function(a,b,c,d){var z,y,x,w
if("createContextualFragment" in window.Range.prototype)return this.c3(a,b,c,d)
z=document
y=z.createDocumentFragment()
z=C.u.a1(z.createElement("table"),b,c,d)
z.toString
z=new W.aa(z)
x=z.gaD(z)
x.toString
z=new W.aa(x)
w=z.gaD(z)
y.toString
w.toString
new W.aa(y).W(0,new W.aa(w))
return y},
"%":"HTMLTableRowElement"},
nL:{"^":"w;",
a1:function(a,b,c,d){var z,y,x
if("createContextualFragment" in window.Range.prototype)return this.c3(a,b,c,d)
z=document
y=z.createDocumentFragment()
z=C.u.a1(z.createElement("table"),b,c,d)
z.toString
z=new W.aa(z)
x=z.gaD(z)
y.toString
x.toString
new W.aa(y).W(0,new W.aa(x))
return y},
"%":"HTMLTableSectionElement"},
es:{"^":"w;",
c_:function(a,b,c,d){var z
a.textContent=null
z=this.a1(a,b,c,d)
a.content.appendChild(z)},
ac:function(a,b){return this.c_(a,b,null,null)},
$ises:1,
"%":"HTMLTemplateElement"},
nM:{"^":"w;R:name=,F:value%","%":"HTMLTextAreaElement"},
nN:{"^":"k;n:width=","%":"TextMetrics"},
jJ:{"^":"ac;","%":"CompositionEvent|FocusEvent|KeyboardEvent|SVGZoomEvent|TextEvent|TouchEvent;UIEvent"},
nS:{"^":"iH;p:height%,n:width%","%":"HTMLVideoElement"},
c3:{"^":"W;",
ghJ:function(a){var z,y
z=P.bi
y=new P.ao(0,$.x,null,[z])
this.fZ(a)
this.ho(a,W.fb(new W.jM(new P.l6(y,[z]))))
return y},
ho:function(a,b){return a.requestAnimationFrame(H.aY(b,1))},
fZ:function(a){if(!!(a.requestAnimationFrame&&a.cancelAnimationFrame))return;(function(b){var z=['ms','moz','webkit','o']
for(var y=0;y<z.length&&!b.requestAnimationFrame;++y){b.requestAnimationFrame=b[z[y]+'RequestAnimationFrame']
b.cancelAnimationFrame=b[z[y]+'CancelAnimationFrame']||b[z[y]+'CancelRequestAnimationFrame']}if(b.requestAnimationFrame&&b.cancelAnimationFrame)return
b.requestAnimationFrame=function(c){return window.setTimeout(function(){c(Date.now())},16)}
b.cancelAnimationFrame=function(c){clearTimeout(c)}})(a)},
$isc3:1,
$isk:1,
$isW:1,
"%":"DOMWindow|Window"},
jM:{"^":"f:0;a",
$1:[function(a){var z=this.a.a
if(z.a!==0)H.B(new P.a5("Future already completed"))
z.bs(a)},null,null,2,0,null,25,"call"]},
nX:{"^":"t;R:name=,dT:namespaceURI=,F:value}","%":"Attr"},
nY:{"^":"k;cE:bottom=,p:height=,bd:left=,d_:right=,bj:top=,n:width=",
j:function(a){return"Rectangle ("+H.b(a.left)+", "+H.b(a.top)+") "+H.b(a.width)+" x "+H.b(a.height)},
G:function(a,b){var z,y,x
if(b==null)return!1
z=J.j(b)
if(!z.$isay)return!1
y=a.left
x=z.gbd(b)
if(y==null?x==null:y===x){y=a.top
x=z.gbj(b)
if(y==null?x==null:y===x){y=a.width
x=z.gn(b)
if(y==null?x==null:y===x){y=a.height
z=z.gp(b)
z=y==null?z==null:y===z}else z=!1}else z=!1}else z=!1
return z},
gI:function(a){var z,y,x,w
z=J.a0(a.left)
y=J.a0(a.top)
x=J.a0(a.width)
w=J.a0(a.height)
return W.eS(W.aJ(W.aJ(W.aJ(W.aJ(0,z),y),x),w))},
gd6:function(a){return new P.al(a.left,a.top,[null])},
$isay:1,
$asay:I.R,
"%":"ClientRect"},
nZ:{"^":"t;",$isk:1,"%":"DocumentType"},
o_:{"^":"hm;",
gp:function(a){return a.height},
gn:function(a){return a.width},
gt:function(a){return a.x},
st:function(a,b){a.x=b},
gu:function(a){return a.y},
su:function(a,b){a.y=b},
"%":"DOMRect"},
o1:{"^":"w;",$isW:1,$isk:1,"%":"HTMLFrameSetElement"},
o4:{"^":"i3;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.aj(b,a,null,null,null))
return a[b]},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
J:function(a,b){if(b>>>0!==b||b>=a.length)return H.a(a,b)
return a[b]},
$ish:1,
$ash:function(){return[W.t]},
$isi:1,
$asi:function(){return[W.t]},
$isZ:1,
$asZ:function(){return[W.t]},
$isT:1,
$asT:function(){return[W.t]},
"%":"MozNamedAttrMap|NamedNodeMap"},
hZ:{"^":"k+X;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
i3:{"^":"hZ+bu;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
o8:{"^":"W;",$isW:1,$isk:1,"%":"ServiceWorker"},
jT:{"^":"e;cl:a<",
K:function(a,b){var z,y,x,w,v
for(z=this.gM(),y=z.length,x=this.a,w=0;w<z.length;z.length===y||(0,H.A)(z),++w){v=z[w]
b.$2(v,x.getAttribute(v))}},
gM:function(){var z,y,x,w,v,u
z=this.a.attributes
y=H.q([],[P.p])
for(x=z.length,w=0;w<x;++w){if(w>=z.length)return H.a(z,w)
v=z[w]
u=J.m(v)
if(u.gdT(v)==null)y.push(u.gR(v))}return y},
gD:function(a){return this.gM().length===0},
gU:function(a){return this.gM().length!==0},
$isG:1,
$asG:function(){return[P.p,P.p]}},
k7:{"^":"jT;a",
N:function(a){return this.a.hasAttribute(a)},
h:function(a,b){return this.a.getAttribute(b)},
l:function(a,b,c){this.a.setAttribute(b,c)},
A:function(a,b){var z,y
z=this.a
y=z.getAttribute(b)
z.removeAttribute(b)
return y},
gi:function(a){return this.gM().length}},
kI:{"^":"aO;a,b",
Y:function(){var z=P.a3(null,null,null,P.p)
C.a.K(this.b,new W.kL(z))
return z},
bT:function(a){var z,y
z=a.bN(0," ")
for(y=this.a,y=new H.bU(y,y.gi(y),0,null);y.m();)J.fP(y.d,z)},
cQ:function(a){C.a.K(this.b,new W.kK(a))},
A:function(a,b){return C.a.ib(this.b,!1,new W.kM(b))},
w:{
kJ:function(a){return new W.kI(a,new H.b7(a,new W.ly(),[H.F(a,0),null]).aM(0))}}},
ly:{"^":"f:16;",
$1:[function(a){return J.cl(a)},null,null,2,0,null,0,"call"]},
kL:{"^":"f:7;a",
$1:function(a){return this.a.W(0,a.Y())}},
kK:{"^":"f:7;a",
$1:function(a){return a.cQ(this.a)}},
kM:{"^":"f:17;a",
$2:function(a,b){return J.fJ(b,this.a)===!0||a===!0}},
k8:{"^":"aO;cl:a<",
Y:function(){var z,y,x,w,v
z=P.a3(null,null,null,P.p)
for(y=this.a.className.split(" "),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=J.cn(y[w])
if(v.length!==0)z.C(0,v)}return z},
bT:function(a){this.a.className=a.bN(0," ")},
gi:function(a){return this.a.classList.length},
gD:function(a){return this.a.classList.length===0},
gU:function(a){return this.a.classList.length!==0},
L:function(a,b){return typeof b==="string"&&this.a.classList.contains(b)},
C:function(a,b){var z,y
z=this.a.classList
y=z.contains(b)
z.add(b)
return!y},
A:function(a,b){var z,y
z=this.a.classList
y=z.contains(b)
z.remove(b)
return y}},
eM:{"^":"ae;a,b,c,$ti",
a2:function(a,b,c,d){return W.K(this.a,this.b,a,!1,H.F(this,0))},
be:function(a,b,c){return this.a2(a,null,b,c)}},
an:{"^":"eM;a,b,c,$ti"},
aR:{"^":"ae;a,b,c,$ti",
a2:function(a,b,c,d){var z,y,x,w
z=H.F(this,0)
y=this.$ti
x=new W.l0(null,new H.a2(0,null,null,null,null,null,0,[[P.ae,z],[P.en,z]]),y)
x.a=new P.c7(null,x.ghR(x),0,null,null,null,null,y)
for(z=this.a,z=new H.bU(z,z.gi(z),0,null),w=this.c;z.m();)x.C(0,new W.eM(z.d,w,!1,y))
z=x.a
z.toString
return new P.jU(z,[H.F(z,0)]).a2(a,b,c,d)},
aA:function(a){return this.a2(a,null,null,null)},
be:function(a,b,c){return this.a2(a,null,b,c)}},
kb:{"^":"en;a,b,c,d,e,$ti",
aJ:function(){if(this.b==null)return
this.e5()
this.b=null
this.d=null
return},
bg:function(a,b){if(this.b==null)return;++this.a
this.e5()},
cV:function(a){return this.bg(a,null)},
gbc:function(){return this.a>0},
cZ:function(){if(this.b==null||this.a<=0)return;--this.a
this.e3()},
e3:function(){var z=this.d
if(z!=null&&this.a<=0)J.fv(this.b,this.c,z,!1)},
e5:function(){var z=this.d
if(z!=null)J.fK(this.b,this.c,z,!1)},
fE:function(a,b,c,d,e){this.e3()},
w:{
K:function(a,b,c,d,e){var z=c==null?null:W.fb(new W.kc(c))
z=new W.kb(0,a,b,z,!1,[e])
z.fE(a,b,c,!1,e)
return z}}},
kc:{"^":"f:0;a",
$1:[function(a){return this.a.$1(a)},null,null,2,0,null,0,"call"]},
l0:{"^":"e;a,b,$ti",
C:function(a,b){var z,y
z=this.b
if(z.N(b))return
y=this.a
z.l(0,b,b.be(y.ghE(y),new W.l1(this,b),y.ghG()))},
A:function(a,b){var z=this.b.A(0,b)
if(z!=null)z.aJ()},
ej:[function(a){var z,y
for(z=this.b,y=z.gd7(z),y=y.gE(y);y.m();)y.gq().aJ()
z.a8(0)
this.a.ej(0)},"$0","ghR",0,0,1]},
l1:{"^":"f:2;a,b",
$0:function(){return this.a.A(0,this.b)}},
cY:{"^":"e;eU:a<",
aH:function(a){return $.$get$eR().L(0,W.b5(a))},
as:function(a,b,c){var z,y,x
z=W.b5(a)
y=$.$get$cZ()
x=y.h(0,H.b(z)+"::"+b)
if(x==null)x=y.h(0,"*::"+b)
if(x==null)return!1
return x.$4(a,b,c,this)},
fH:function(a){var z,y
z=$.$get$cZ()
if(z.gD(z)){for(y=0;y<262;++y)z.l(0,C.I[y],W.lG())
for(y=0;y<12;++y)z.l(0,C.k[y],W.lH())}},
w:{
eQ:function(a){var z,y
z=W.ds(null)
y=window.location
z=new W.cY(new W.kV(z,y))
z.fH(a)
return z},
o2:[function(a,b,c,d){return!0},"$4","lG",8,0,8,12,7,2,13],
o3:[function(a,b,c,d){var z,y,x,w,v
z=d.geU()
y=z.a
y.href=c
x=y.hostname
z=z.b
w=z.hostname
if(x==null?w==null:x===w){w=y.port
v=z.port
if(w==null?v==null:w===v){w=y.protocol
z=z.protocol
z=w==null?z==null:w===z}else z=!1}else z=!1
if(!z)if(x==="")if(y.port===""){z=y.protocol
z=z===":"||z===""}else z=!1
else z=!1
else z=!0
return z},"$4","lH",8,0,8,12,7,2,13]}},
bu:{"^":"e;$ti",
gE:function(a){return new W.dO(a,this.gi(a),-1,null)},
C:function(a,b){throw H.c(new P.u("Cannot add to immutable List."))},
ah:function(a,b){throw H.c(new P.u("Cannot remove from immutable List."))},
A:function(a,b){throw H.c(new P.u("Cannot remove from immutable List."))},
Z:function(a,b,c,d,e){throw H.c(new P.u("Cannot setRange on immutable List."))},
$ish:1,
$ash:null,
$isi:1,
$asi:null},
e3:{"^":"e;a",
C:function(a,b){this.a.push(b)},
aH:function(a){return C.a.eb(this.a,new W.iN(a))},
as:function(a,b,c){return C.a.eb(this.a,new W.iM(a,b,c))}},
iN:{"^":"f:0;a",
$1:function(a){return a.aH(this.a)}},
iM:{"^":"f:0;a,b,c",
$1:function(a){return a.as(this.a,this.b,this.c)}},
kW:{"^":"e;eU:d<",
aH:function(a){return this.a.L(0,W.b5(a))},
as:["fs",function(a,b,c){var z,y
z=W.b5(a)
y=this.c
if(y.L(0,H.b(z)+"::"+b))return this.d.hI(c)
else if(y.L(0,"*::"+b))return this.d.hI(c)
else{y=this.b
if(y.L(0,H.b(z)+"::"+b))return!0
else if(y.L(0,"*::"+b))return!0
else if(y.L(0,H.b(z)+"::*"))return!0
else if(y.L(0,"*::*"))return!0}return!1}],
fI:function(a,b,c,d){var z,y,x
this.a.W(0,c)
z=b.d8(0,new W.kX())
y=b.d8(0,new W.kY())
this.b.W(0,z)
x=this.c
x.W(0,C.i)
x.W(0,y)}},
kX:{"^":"f:0;",
$1:function(a){return!C.a.L(C.k,a)}},
kY:{"^":"f:0;",
$1:function(a){return C.a.L(C.k,a)}},
l7:{"^":"kW;e,a,b,c,d",
as:function(a,b,c){if(this.fs(a,b,c))return!0
if(b==="template"&&c==="")return!0
if(J.dk(a).a.getAttribute("template")==="")return this.e.L(0,b)
return!1},
w:{
eW:function(){var z=P.p
z=new W.l7(P.dW(C.j,z),P.a3(null,null,null,z),P.a3(null,null,null,z),P.a3(null,null,null,z),null)
z.fI(null,new H.b7(C.j,new W.l8(),[H.F(C.j,0),null]),["TEMPLATE"],null)
return z}}},
l8:{"^":"f:0;",
$1:[function(a){return"TEMPLATE::"+H.b(a)},null,null,2,0,null,26,"call"]},
l2:{"^":"e;",
aH:function(a){var z=J.j(a)
if(!!z.$isei)return!1
z=!!z.$isz
if(z&&W.b5(a)==="foreignObject")return!1
if(z)return!0
return!1},
as:function(a,b,c){if(b==="is"||C.e.fc(b,"on"))return!1
return this.aH(a)}},
dO:{"^":"e;a,b,c,d",
m:function(){var z,y
z=this.c+1
y=this.b
if(z<y){this.d=J.ag(this.a,z)
this.c=z
return!0}this.d=null
this.c=y
return!1},
gq:function(){return this.d}},
k1:{"^":"e;a",
e9:function(a,b,c,d){return H.B(new P.u("You can only attach EventListeners to your own window."))},
eK:function(a,b,c,d){return H.B(new P.u("You can only attach EventListeners to your own window."))},
$isW:1,
$isk:1,
w:{
k2:function(a){if(a===window)return a
else return new W.k1(a)}}},
e2:{"^":"e;"},
kV:{"^":"e;a,b"},
eX:{"^":"e;a",
dd:function(a){new W.la(this).$2(a,null)},
b_:function(a,b){var z
if(b==null){z=a.parentNode
if(z!=null)z.removeChild(a)}else b.removeChild(a)},
ht:function(a,b){var z,y,x,w,v,u,t,s
z=!0
y=null
x=null
try{y=J.dk(a)
x=y.gcl().getAttribute("is")
w=function(c){if(!(c.attributes instanceof NamedNodeMap))return true
var r=c.childNodes
if(c.lastChild&&c.lastChild!==r[r.length-1])return true
if(c.children)if(!(c.children instanceof HTMLCollection||c.children instanceof NodeList))return true
var q=0
if(c.children)q=c.children.length
for(var p=0;p<q;p++){var o=c.children[p]
if(o.id=='attributes'||o.name=='attributes'||o.id=='lastChild'||o.name=='lastChild'||o.id=='children'||o.name=='children')return true}return false}(a)
z=w===!0?!0:!(a.attributes instanceof NamedNodeMap)}catch(t){H.D(t)}v="element unprintable"
try{v=J.C(a)}catch(t){H.D(t)}try{u=W.b5(a)
this.hs(a,b,z,v,u,y,x)}catch(t){if(H.D(t) instanceof P.as)throw t
else{this.b_(a,b)
window
s="Removing corrupted element "+H.b(v)
if(typeof console!="undefined")console.warn(s)}}},
hs:function(a,b,c,d,e,f,g){var z,y,x,w,v
if(c){this.b_(a,b)
window
z="Removing element due to corrupted attributes on <"+d+">"
if(typeof console!="undefined")console.warn(z)
return}if(!this.a.aH(a)){this.b_(a,b)
window
z="Removing disallowed element <"+H.b(e)+"> from "+J.C(b)
if(typeof console!="undefined")console.warn(z)
return}if(g!=null)if(!this.a.as(a,"is",g)){this.b_(a,b)
window
z="Removing disallowed type extension <"+H.b(e)+' is="'+g+'">'
if(typeof console!="undefined")console.warn(z)
return}z=f.gM()
y=H.q(z.slice(0),[H.F(z,0)])
for(x=f.gM().length-1,z=f.a;x>=0;--x){if(x>=y.length)return H.a(y,x)
w=y[x]
if(!this.a.as(a,J.fU(w),z.getAttribute(w))){window
v="Removing disallowed attribute <"+H.b(e)+" "+H.b(w)+'="'+H.b(z.getAttribute(w))+'">'
if(typeof console!="undefined")console.warn(v)
z.getAttribute(w)
z.removeAttribute(w)}}if(!!J.j(a).$ises)this.dd(a.content)}},
la:{"^":"f:18;a",
$2:function(a,b){var z,y,x,w,v,u
x=this.a
switch(a.nodeType){case 1:x.ht(a,b)
break
case 8:case 11:case 3:case 4:break
default:x.b_(a,b)}z=a.lastChild
for(x=a==null;null!=z;){y=null
try{y=J.fD(z)}catch(w){H.D(w)
v=z
if(x){u=J.m(v)
if(u.gcU(v)!=null){u.gcU(v)
u.gcU(v).removeChild(v)}}else a.removeChild(v)
z=null
y=a.lastChild}if(z!=null)this.$2(z,a)
z=y}}}}],["","",,P,{"^":"",
dJ:function(){var z=$.dI
if(z==null){z=J.ck(window.navigator.userAgent,"Opera",0)
$.dI=z}return z},
hj:function(){var z,y
z=$.dF
if(z!=null)return z
y=$.dG
if(y==null){y=J.ck(window.navigator.userAgent,"Firefox",0)
$.dG=y}if(y)z="-moz-"
else{y=$.dH
if(y==null){y=P.dJ()!==!0&&J.ck(window.navigator.userAgent,"Trident/",0)
$.dH=y}if(y)z="-ms-"
else z=P.dJ()===!0?"-o-":"-webkit-"}$.dF=z
return z},
aO:{"^":"e;",
cB:function(a){if($.$get$dE().b.test(H.d6(a)))return a
throw H.c(P.co(a,"value","Not a valid class token"))},
j:function(a){return this.Y().bN(0," ")},
gE:function(a){var z,y
z=this.Y()
y=new P.bG(z,z.r,null,null)
y.c=z.e
return y},
ag:function(a,b){var z=this.Y()
return new H.cx(z,b,[H.F(z,0),null])},
gD:function(a){return this.Y().a===0},
gU:function(a){return this.Y().a!==0},
gi:function(a){return this.Y().a},
L:function(a,b){if(typeof b!=="string")return!1
this.cB(b)
return this.Y().L(0,b)},
cO:function(a){return this.L(0,a)?a:null},
C:function(a,b){this.cB(b)
return this.cQ(new P.hc(b))},
A:function(a,b){var z,y
this.cB(b)
z=this.Y()
y=z.A(0,b)
this.bT(z)
return y},
J:function(a,b){return this.Y().J(0,b)},
cQ:function(a){var z,y
z=this.Y()
y=a.$1(z)
this.bT(z)
return y},
$isi:1,
$asi:function(){return[P.p]}},
hc:{"^":"f:0;a",
$1:function(a){return a.C(0,this.a)}},
hN:{"^":"aQ;a,b",
gaq:function(){var z,y
z=this.b
y=H.I(z,"X",0)
return new H.bV(new H.cU(z,new P.hO(),[y]),new P.hP(),[y,null])},
l:function(a,b,c){var z=this.gaq()
J.fM(z.b.$1(J.b1(z.a,b)),c)},
si:function(a,b){var z=J.a1(this.gaq().a)
if(b>=z)return
else if(b<0)throw H.c(P.aB("Invalid list length"))
this.iJ(0,b,z)},
C:function(a,b){this.b.a.appendChild(b)},
Z:function(a,b,c,d,e){throw H.c(new P.u("Cannot setRange on filtered list"))},
iJ:function(a,b,c){var z=this.gaq()
z=H.jl(z,b,H.I(z,"Q",0))
C.a.K(P.av(H.ju(z,c-b,H.I(z,"Q",0)),!0,null),new P.hQ())},
a8:function(a){J.di(this.b.a)},
ah:function(a,b){var z,y
z=this.gaq()
y=z.b.$1(J.b1(z.a,b))
J.bm(y)
return y},
A:function(a,b){return!1},
gi:function(a){return J.a1(this.gaq().a)},
h:function(a,b){var z=this.gaq()
return z.b.$1(J.b1(z.a,b))},
gE:function(a){var z=P.av(this.gaq(),!1,W.N)
return new J.bo(z,z.length,0,null)},
$asaQ:function(){return[W.N]},
$ash:function(){return[W.N]},
$asi:function(){return[W.N]}},
hO:{"^":"f:0;",
$1:function(a){return!!J.j(a).$isN}},
hP:{"^":"f:0;",
$1:[function(a){return H.cd(a,"$isN")},null,null,2,0,null,27,"call"]},
hQ:{"^":"f:0;",
$1:function(a){return J.bm(a)}}}],["","",,P,{"^":"",cJ:{"^":"k;",$iscJ:1,"%":"IDBKeyRange"}}],["","",,P,{"^":"",
lc:[function(a,b,c,d){var z,y,x
if(b===!0){z=[c]
C.a.W(z,d)
d=z}y=P.av(J.dp(d,P.lU()),!0,null)
x=H.iX(a,y)
return P.f1(x)},null,null,8,0,null,28,29,30,31],
d2:function(a,b,c){var z
try{if(Object.isExtensible(a)&&!Object.prototype.hasOwnProperty.call(a,b)){Object.defineProperty(a,b,{value:c})
return!0}}catch(z){H.D(z)}return!1},
f3:function(a,b){if(Object.prototype.hasOwnProperty.call(a,b))return a[b]
return},
f1:[function(a){var z
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
z=J.j(a)
if(!!z.$isbz)return a.a
if(!!z.$iscq||!!z.$isac||!!z.$iscJ||!!z.$iscD||!!z.$ist||!!z.$isa9||!!z.$isc3)return a
if(!!z.$isb4)return H.Y(a)
if(!!z.$iscC)return P.f2(a,"$dart_jsFunction",new P.le())
return P.f2(a,"_$dart_jsObject",new P.lf($.$get$d1()))},"$1","lV",2,0,0,14],
f2:function(a,b,c){var z=P.f3(a,b)
if(z==null){z=c.$1(a)
P.d2(a,b,z)}return z},
f0:[function(a){var z,y
if(a==null||typeof a=="string"||typeof a=="number"||typeof a=="boolean")return a
else{if(a instanceof Object){z=J.j(a)
z=!!z.$iscq||!!z.$isac||!!z.$iscJ||!!z.$iscD||!!z.$ist||!!z.$isa9||!!z.$isc3}else z=!1
if(z)return a
else if(a instanceof Date){z=0+a.getTime()
y=new P.b4(z,!1)
y.di(z,!1)
return y}else if(a.constructor===$.$get$d1())return a.o
else return P.fa(a)}},"$1","lU",2,0,22,14],
fa:function(a){if(typeof a=="function")return P.d3(a,$.$get$bO(),new P.lo())
if(a instanceof Array)return P.d3(a,$.$get$cX(),new P.lp())
return P.d3(a,$.$get$cX(),new P.lq())},
d3:function(a,b,c){var z=P.f3(a,b)
if(z==null||!(a instanceof Object)){z=c.$1(a)
P.d2(a,b,z)}return z},
bz:{"^":"e;a",
h:["fl",function(a,b){if(typeof b!=="string"&&typeof b!=="number")throw H.c(P.aB("property is not a String or num"))
return P.f0(this.a[b])}],
l:["df",function(a,b,c){if(typeof b!=="string"&&typeof b!=="number")throw H.c(P.aB("property is not a String or num"))
this.a[b]=P.f1(c)}],
gI:function(a){return 0},
G:function(a,b){if(b==null)return!1
return b instanceof P.bz&&this.a===b.a},
j:function(a){var z,y
try{z=String(this.a)
return z}catch(y){H.D(y)
z=this.fn(this)
return z}},
bI:function(a,b){var z,y
z=this.a
y=b==null?null:P.av(new H.b7(b,P.lV(),[H.F(b,0),null]),!0,null)
return P.f0(z[a].apply(z,y))}},
ir:{"^":"bz;a"},
ip:{"^":"iu;a,$ti",
fN:function(a){var z
if(typeof a==="number"&&Math.floor(a)===a)z=a<0||a>=this.gi(this)
else z=!1
if(z)throw H.c(P.H(a,0,this.gi(this),null,null))},
h:function(a,b){var z
if(typeof b==="number"&&b===C.d.d5(b)){if(typeof b==="number"&&Math.floor(b)===b)z=b<0||b>=this.gi(this)
else z=!1
if(z)H.B(P.H(b,0,this.gi(this),null,null))}return this.fl(0,b)},
l:function(a,b,c){var z
if(typeof b==="number"&&b===C.d.d5(b)){if(typeof b==="number"&&Math.floor(b)===b)z=b<0||b>=this.gi(this)
else z=!1
if(z)H.B(P.H(b,0,this.gi(this),null,null))}this.df(0,b,c)},
gi:function(a){var z=this.a.length
if(typeof z==="number"&&z>>>0===z)return z
throw H.c(new P.a5("Bad JsArray length"))},
si:function(a,b){this.df(0,"length",b)},
C:function(a,b){this.bI("push",[b])},
ah:function(a,b){this.fN(b)
return J.ag(this.bI("splice",[b,1]),0)},
Z:function(a,b,c,d,e){var z,y
P.iq(b,c,this.gi(this))
z=c-b
if(z===0)return
y=[b,z]
C.a.W(y,new H.cQ(d,e,null,[H.I(d,"X",0)]).iO(0,z))
this.bI("splice",y)},
w:{
iq:function(a,b,c){if(a>c)throw H.c(P.H(a,0,c,null,null))
if(b<a||b>c)throw H.c(P.H(b,a,c,null,null))}}},
iu:{"^":"bz+X;",$ash:null,$asi:null,$ish:1,$isi:1},
le:{"^":"f:0;",
$1:function(a){var z=function(b,c,d){return function(){return b(c,d,this,Array.prototype.slice.apply(arguments))}}(P.lc,a,!1)
P.d2(z,$.$get$bO(),a)
return z}},
lf:{"^":"f:0;a",
$1:function(a){return new this.a(a)}},
lo:{"^":"f:0;",
$1:function(a){return new P.ir(a)}},
lp:{"^":"f:0;",
$1:function(a){return new P.ip(a,[null])}},
lq:{"^":"f:0;",
$1:function(a){return new P.bz(a)}}}],["","",,P,{"^":"",
bb:function(a,b){a=536870911&a+b
a=536870911&a+((524287&a)<<10)
return a^a>>>6},
eT:function(a){a=536870911&a+((67108863&a)<<3)
a^=a>>>11
return 536870911&a+((16383&a)<<15)},
al:{"^":"e;t:a>,u:b>,$ti",
j:function(a){return"Point("+H.b(this.a)+", "+H.b(this.b)+")"},
G:function(a,b){var z,y
if(b==null)return!1
if(!(b instanceof P.al))return!1
z=this.a
y=b.a
if(z==null?y==null:z===y){z=this.b
y=b.b
y=z==null?y==null:z===y
z=y}else z=!1
return z},
gI:function(a){var z,y
z=J.a0(this.a)
y=J.a0(this.b)
return P.eT(P.bb(P.bb(0,z),y))},
v:function(a,b){var z,y,x,w
z=this.a
y=J.m(b)
x=y.gt(b)
if(typeof z!=="number")return z.v()
if(typeof x!=="number")return H.l(x)
w=this.b
y=y.gu(b)
if(typeof w!=="number")return w.v()
if(typeof y!=="number")return H.l(y)
return new P.al(z+x,w+y,this.$ti)},
V:function(a,b){var z,y,x,w
z=this.a
y=J.m(b)
x=y.gt(b)
if(typeof z!=="number")return z.V()
if(typeof x!=="number")return H.l(x)
w=this.b
y=y.gu(b)
if(typeof w!=="number")return w.V()
if(typeof y!=="number")return H.l(y)
return new P.al(z-x,w-y,this.$ti)},
H:function(a,b){var z,y
z=this.a
if(typeof z!=="number")return z.H()
if(typeof b!=="number")return H.l(b)
y=this.b
if(typeof y!=="number")return y.H()
return new P.al(z*b,y*b,this.$ti)}},
kQ:{"^":"e;$ti",
gd_:function(a){var z,y
z=this.a
y=this.c
if(typeof z!=="number")return z.v()
if(typeof y!=="number")return H.l(y)
return z+y},
gcE:function(a){var z,y
z=this.b
y=this.d
if(typeof z!=="number")return z.v()
if(typeof y!=="number")return H.l(y)
return z+y},
j:function(a){return"Rectangle ("+H.b(this.a)+", "+H.b(this.b)+") "+H.b(this.c)+" x "+H.b(this.d)},
G:function(a,b){var z,y,x,w
if(b==null)return!1
z=J.j(b)
if(!z.$isay)return!1
y=this.a
x=z.gbd(b)
if(y==null?x==null:y===x){x=this.b
w=z.gbj(b)
if(x==null?w==null:x===w){w=this.c
if(typeof y!=="number")return y.v()
if(typeof w!=="number")return H.l(w)
if(y+w===z.gd_(b)){y=this.d
if(typeof x!=="number")return x.v()
if(typeof y!=="number")return H.l(y)
z=x+y===z.gcE(b)}else z=!1}else z=!1}else z=!1
return z},
gI:function(a){var z,y,x,w,v,u
z=this.a
y=J.a0(z)
x=this.b
w=J.a0(x)
v=this.c
if(typeof z!=="number")return z.v()
if(typeof v!=="number")return H.l(v)
u=this.d
if(typeof x!=="number")return x.v()
if(typeof u!=="number")return H.l(u)
return P.eT(P.bb(P.bb(P.bb(P.bb(0,y),w),z+v&0x1FFFFFFF),x+u&0x1FFFFFFF))},
gd6:function(a){return new P.al(this.a,this.b,this.$ti)}},
ay:{"^":"kQ;bd:a>,bj:b>,n:c>,p:d>,$ti",$asay:null,w:{
jc:function(a,b,c,d,e){var z,y
if(typeof c!=="number")return c.ak()
if(c<0)z=-c*0
else z=c
if(typeof d!=="number")return d.ak()
if(d<0)y=-d*0
else y=d
return new P.ay(a,b,z,y,[e])}}}}],["","",,P,{"^":"",mc:{"^":"aP;",$isk:1,"%":"SVGAElement"},md:{"^":"z;",$isk:1,"%":"SVGAnimateElement|SVGAnimateMotionElement|SVGAnimateTransformElement|SVGAnimationElement|SVGSetElement"},mp:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEBlendElement"},mq:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEColorMatrixElement"},mr:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEComponentTransferElement"},ms:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFECompositeElement"},mt:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEConvolveMatrixElement"},mu:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEDiffuseLightingElement"},mv:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEDisplacementMapElement"},mw:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEFloodElement"},mx:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEGaussianBlurElement"},my:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEImageElement"},mz:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEMergeElement"},mA:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEMorphologyElement"},mB:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFEOffsetElement"},mC:{"^":"z;t:x=,u:y=","%":"SVGFEPointLightElement"},mD:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFESpecularLightingElement"},mE:{"^":"z;t:x=,u:y=","%":"SVGFESpotLightElement"},mF:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFETileElement"},mG:{"^":"z;p:height=,O:result=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFETurbulenceElement"},mI:{"^":"z;p:height=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGFilterElement"},mJ:{"^":"aP;p:height=,n:width=,t:x=,u:y=","%":"SVGForeignObjectElement"},hR:{"^":"aP;","%":"SVGCircleElement|SVGEllipseElement|SVGLineElement|SVGPathElement|SVGPolygonElement|SVGPolylineElement;SVGGeometryElement"},aP:{"^":"z;",$isk:1,"%":"SVGClipPathElement|SVGDefsElement|SVGGElement|SVGSwitchElement;SVGGraphicsElement"},mO:{"^":"aP;p:height=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGImageElement"},b6:{"^":"k;",$ise:1,"%":"SVGLength"},n_:{"^":"i4;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.aj(b,a,null,null,null))
return a.getItem(b)},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
J:function(a,b){return this.h(a,b)},
$ish:1,
$ash:function(){return[P.b6]},
$isi:1,
$asi:function(){return[P.b6]},
"%":"SVGLengthList"},i_:{"^":"k+X;",
$ash:function(){return[P.b6]},
$asi:function(){return[P.b6]},
$ish:1,
$isi:1},i4:{"^":"i_+bu;",
$ash:function(){return[P.b6]},
$asi:function(){return[P.b6]},
$ish:1,
$isi:1},n3:{"^":"z;",$isk:1,"%":"SVGMarkerElement"},n4:{"^":"z;p:height=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGMaskElement"},b9:{"^":"k;",$ise:1,"%":"SVGNumber"},no:{"^":"i5;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.aj(b,a,null,null,null))
return a.getItem(b)},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
J:function(a,b){return this.h(a,b)},
$ish:1,
$ash:function(){return[P.b9]},
$isi:1,
$asi:function(){return[P.b9]},
"%":"SVGNumberList"},i0:{"^":"k+X;",
$ash:function(){return[P.b9]},
$asi:function(){return[P.b9]},
$ish:1,
$isi:1},i5:{"^":"i0+bu;",
$ash:function(){return[P.b9]},
$asi:function(){return[P.b9]},
$ish:1,
$isi:1},nu:{"^":"z;p:height=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGPatternElement"},ny:{"^":"hR;p:height=,n:width=,t:x=,u:y=","%":"SVGRectElement"},ei:{"^":"z;P:type}",$isei:1,$isk:1,"%":"SVGScriptElement"},nH:{"^":"z;P:type}","%":"SVGStyleElement"},fX:{"^":"aO;a",
Y:function(){var z,y,x,w,v,u
z=this.a.getAttribute("class")
y=P.a3(null,null,null,P.p)
if(z==null)return y
for(x=z.split(" "),w=x.length,v=0;v<x.length;x.length===w||(0,H.A)(x),++v){u=J.cn(x[v])
if(u.length!==0)y.C(0,u)}return y},
bT:function(a){this.a.setAttribute("class",a.bN(0," "))}},z:{"^":"N;",
gcF:function(a){return new P.fX(a)},
gei:function(a){return new P.hN(a,new W.aa(a))},
sex:function(a,b){this.ac(a,b)},
a1:function(a,b,c,d){var z,y,x,w,v,u
z=H.q([],[W.e2])
z.push(W.eQ(null))
z.push(W.eW())
z.push(new W.l2())
c=new W.eX(new W.e3(z))
y='<svg version="1.1">'+H.b(b)+"</svg>"
z=document
x=z.body
w=(x&&C.n).hU(x,y,c)
v=z.createDocumentFragment()
w.toString
z=new W.aa(w)
u=z.gaD(z)
for(;z=u.firstChild,z!=null;)v.appendChild(z)
return v},
eo:function(a){return a.focus()},
gbQ:function(a){return new W.an(a,"change",!1,[W.ac])},
gcT:function(a){return new W.an(a,"input",!1,[W.ac])},
geD:function(a){return new W.an(a,"mousedown",!1,[W.U])},
geE:function(a){return new W.an(a,"mousemove",!1,[W.U])},
geF:function(a){return new W.an(a,"mouseup",!1,[W.U])},
$isz:1,
$isW:1,
$isk:1,
"%":"SVGComponentTransferFunctionElement|SVGDescElement|SVGDiscardElement|SVGFEDistantLightElement|SVGFEFuncAElement|SVGFEFuncBElement|SVGFEFuncGElement|SVGFEFuncRElement|SVGFEMergeNodeElement|SVGMetadataElement|SVGStopElement|SVGTitleElement;SVGElement"},nI:{"^":"aP;p:height=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGSVGElement"},nJ:{"^":"z;",$isk:1,"%":"SVGSymbolElement"},et:{"^":"aP;","%":";SVGTextContentElement"},nO:{"^":"et;",$isk:1,"%":"SVGTextPathElement"},nP:{"^":"et;t:x=,u:y=","%":"SVGTSpanElement|SVGTextElement|SVGTextPositioningElement"},nR:{"^":"aP;p:height=,n:width=,t:x=,u:y=",$isk:1,"%":"SVGUseElement"},nT:{"^":"z;",$isk:1,"%":"SVGViewElement"},o0:{"^":"z;",$isk:1,"%":"SVGGradientElement|SVGLinearGradientElement|SVGRadialGradientElement"},o5:{"^":"z;",$isk:1,"%":"SVGCursorElement"},o6:{"^":"z;",$isk:1,"%":"SVGFEDropShadowElement"},o7:{"^":"z;",$isk:1,"%":"SVGMPathElement"}}],["","",,P,{"^":""}],["","",,P,{"^":"",nz:{"^":"k;",$isk:1,"%":"WebGL2RenderingContext"}}],["","",,P,{"^":""}],["","",,U,{"^":"",
h6:function(a,b){var z
if($.bq==null){z=new H.a2(0,null,null,null,null,null,0,[P.p,U.cu])
$.bq=z
z.l(0,"NetLogo",new U.iJ("  "))
$.bq.l(0,"plain",new U.iU("  "))}if($.bq.N(a))return $.bq.h(0,a).dJ(b)
else return C.h.cJ(b)},
mS:[function(a,b){var z,y
if($.$get$S().h(0,a) instanceof U.cv){z=$.$get$S().h(0,a)
C.a.si(z.a,0)
C.a.si(z.r,0)
C.a.A(z.db.c,z)}y=C.h.ek(b)
if(!!J.j(y).$isG){$.$get$S().l(0,a,U.dz(a,y))
$.$get$S().h(0,a).X()}},"$2","m_",4,0,23,3,15],
mR:[function(a){var z,y,x,w,v
z=C.h.ek(a)
y=J.j(z)
if(!!y.$isG)for(x=J.E(z.gM());x.m();){w=x.gq()
if($.$get$S().h(0,w) instanceof U.cv){v=$.$get$S().h(0,w)
C.a.si(v.a,0)
C.a.si(v.r,0)
C.a.A(v.db.c,v)}if(!!J.j(y.h(z,w)).$isG){$.$get$S().l(0,w,U.dz(w,y.h(z,w)))
$.$get$S().h(0,w).X()}}},"$1","lZ",2,0,24,15],
mQ:[function(a,b){if($.$get$S().N(a))return U.h6(b,$.$get$S().h(0,a).b7())
return},"$2","lY",4,0,25,3,24],
mU:[function(a){var z
if($.$get$S().N(a)){z=$.$get$S().h(0,a).x
J.aA(z,"program",$.$get$S().h(0,a).b7())
return C.h.cJ(z)}},"$1","m1",2,0,26,3],
mT:[function(){var z,y,x,w
z=P.bA()
for(y=$.$get$S().gM(),y=y.gE(y);y.m();){x=y.gq()
w=$.$get$S().h(0,x).x
J.aA(w,"program",$.$get$S().h(0,x).b7())
z.l(0,x,w)}return C.h.cJ(z)},"$0","m0",0,0,27],
of:[function(){var z=$.$get$d8()
J.aA(z,"NetTango_InitWorkspace",U.m_())
J.aA(z,"NetTango_InitAllWorkspaces",U.lZ())
J.aA(z,"NetTango_ExportCode",U.lY())
J.aA(z,"NetTango_Save",U.m1())
J.aA(z,"NetTango_SaveAll",U.m0())},"$0","fl",0,0,1],
df:function(a,b){var z,y
if(a==null)return b
else if(typeof a==="number"&&Math.floor(a)===a)return a
else if(typeof a==="string")try{z=H.ee(a,null,null)
return z}catch(y){if(!!J.j(H.D(y)).$isbP)return b
else throw y}return b},
aq:function(a,b){var z,y
if(a==null)return b
else if(typeof a==="number")return a
else if(typeof a==="string")try{z=P.fm(a,null)
return z}catch(y){if(!!J.j(H.D(y)).$isbP)return b
else throw y}return b},
ci:function(a,b){if(a==null)return b
else if(typeof a==="boolean")return a
else if(typeof a==="string")if(a.toLowerCase()==="true"||a.toLowerCase()==="t")return!0
else if(a.toLowerCase()==="false"||a.toLowerCase()==="f")return!1
return b},
bp:{"^":"e;a,cC:b>,P:c',d,t:e*,u:f*,n:r>,x,a_:y@,bR:z@,ew:Q<,ch,eH:cx<,eJ:cy<,db,dx,dy,fr,fx,fy,eu:go<,dF:id<,k1,k2,k3,k4,dQ:r1<,e7:r2<",
gp:function(a){return this.r1?$.$get$o():this.x},
gb9:function(){return 0},
gaL:function(){return 0},
gb8:function(){return this.y!=null},
ges:function(){return this.z!=null},
gbk:function(){return this.f},
gee:function(){var z=this.f
return J.d(z,this.r1?$.$get$o():this.x)},
gb2:function(){var z=this.y
return z!=null?z.gb2():this},
gbO:function(){var z=this.y
if(!(z!=null)){z=this.ch
z=z!=null?z.rx:null}return z},
gez:function(){return this.z==null},
at:function(a){var z=U.fZ(this.fy,this.b)
this.cc(z)
return z},
cc:function(a){var z,y,x,w
a.b=this.b
a.c=this.c
a.d=this.d
a.db=this.db
a.dx=this.dx
a.dy=this.dy
a.fr=this.fr
a.fx=this.fx
a.r=this.r
a.x=this.x
a.go=this.go
for(z=this.cx,y=z.length,x=a.cx,w=0;w<z.length;z.length===y||(0,H.A)(z),++w)x.push(J.dj(z[w],a))
for(z=this.cy,y=z.length,x=a.cy,w=0;w<z.length;z.length===y||(0,H.A)(z),++w)x.push(J.dj(z[w],a))},
T:function(){var z,y,x,w,v,u
z=P.bA()
z.l(0,"id",this.a)
z.l(0,"action",this.b)
z.l(0,"type",this.c)
z.l(0,"format",this.d)
z.l(0,"start",this.go)
z.l(0,"required",this.fx)
y=this.e
x=$.$get$cp()
z.l(0,"x",J.cj(y,x))
z.l(0,"y",J.cj(this.f,x))
y=this.cx
if(y.length!==0){z.l(0,"params",[])
for(x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=y[w]
J.ar(z.h(0,"params"),v.T())}}y=this.cy
if(y.length!==0){z.l(0,"properties",[])
for(x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){u=y[w]
J.ar(z.h(0,"properties"),u.T())}}return z},
b7:function(){var z=[]
this.a6(z)
return z},
a6:function(a){var z
J.ar(a,this.T())
z=this.y
if(z!=null)z.a6(a)},
bB:function(a,b){var z,y,x,w,v,u,t,s,r
z=$.$get$ab()
y=this.dL(a)
x=$.$get$O()
if(typeof x!=="number")return x.H()
if(typeof y!=="number")return y.v()
this.r=Math.max(H.bJ(z),y+x*2)
if(!this.r1&&this.cx.length!==0)for(z=this.cx,y=z.length,w=0,v=0;v<z.length;z.length===y||(0,H.A)(z),++v){u=z[v]
u.bA(a)
t=J.d(J.dm(u),x)
if(typeof t!=="number")return H.l(t)
w+=t}else w=0
if(!this.r1&&this.cy.length!==0)for(z=this.cy,y=z.length,s=0,v=0;v<z.length;z.length===y||(0,H.A)(z),++v)s=Math.max(s,z[v].hp(a))
else s=0
z=J.d(this.e,s)
y=J.d(J.d(this.e,this.r),w)
y=Math.max(H.bJ(z),H.bJ(y))
b=Math.max(H.bJ(b),y)
r=this.gbO()
if(r!=null)b=r.bB(a,b)
z=this.e
if(typeof z!=="number")return H.l(z)
this.r=b-z
return b},
a7:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a7(a+this.gaL(),b)},
b0:["fg",function(){var z,y,x,w,v
z=this.y
if(z!=null){y=this.f
J.fT(z,J.d(y,this.r1?$.$get$o():this.x))
z=this.y
y=this.e
x=z.gew()
w=this.Q
if(typeof x!=="number")return x.V()
v=$.$get$aC()
if(typeof v!=="number")return H.l(v)
J.fS(z,J.d(y,(x-w)*v))
this.y.b0()}}],
dL:function(a){var z,y
z=J.m(a)
z.a0(a)
z.saK(a,this.fr)
y=z.cP(a,this.b).width
z.a4(a)
return y},
bG:function(a){var z,y,x
if(this.id){z=this.e
y=this.k1
x=this.k3
if(typeof y!=="number")return y.V()
if(typeof x!=="number")return H.l(x)
this.e=J.d(z,y-x)
x=this.f
y=this.k2
z=this.k4
if(typeof y!=="number")return y.V()
if(typeof z!=="number")return H.l(z)
this.f=J.d(x,y-z)
this.k3=this.k1
this.k4=this.k2}return this.id},
ce:function(a){var z,y,x,w,v
z=J.m(a)
z.a0(a)
z.saw(a,this.dx)
z.saK(a,this.fr)
z.sd3(a,"left")
z.sd4(a,"middle")
y=this.b
x=J.d(this.e,$.$get$O())
w=this.f
v=$.$get$o()
if(typeof v!=="number")return v.aj()
z.cL(a,y,x,J.d(w,v/2))
z.a4(a)},
cf:function(a){var z,y
z=J.m(a)
z.a0(a)
this.cr(a)
z.sc2(a,this.dy)
y=$.$get$V()
if(typeof y!=="number")return H.l(y)
z.scN(a,0.5*y)
z.siy(a,"round")
z.c1(a)
z.a4(a)},
cd:function(a){var z=J.m(a)
z.a0(a)
this.cr(a)
z.saw(a,this.db)
z.cK(a)
z.saw(a,"rgba(0, 0, 0, "+H.b(Math.min(1,0.075*this.Q)))
z.cK(a)
z.a4(a)},
fW:function(a){var z,y,x,w
z=J.m(a)
z.a0(a)
z.scN(a,5)
z.sc2(a,"cyan")
z.aI(a)
y=J.d(this.e,$.$get$O())
x=$.$get$aC()
w=this.gb9()
if(typeof x!=="number")return x.H()
z.bf(a,J.d(y,x*w),this.f)
this.ct(a,this.z==null&&this.go)
z.c1(a)
z.a4(a)},
fT:function(a){var z,y,x
z=J.m(a)
z.a0(a)
z.scN(a,5)
z.sc2(a,"cyan")
z.aI(a)
y=J.r(J.d(this.e,this.r),$.$get$O())
x=this.f
z.bf(a,y,J.d(x,this.r1?$.$get$o():this.x))
this.cs(a,this.y==null&&this.Q===0)
z.c1(a)
z.a4(a)},
fU:function(a){var z,y,x,w,v
z=this.r
for(y=this.cx,x=y.length-1;x>=0;--x){w=$.$get$O()
if(x>=y.length)return H.a(y,x)
v=J.dm(y[x])
if(typeof w!=="number")return w.v()
if(typeof v!=="number")return H.l(v)
if(typeof z!=="number")return z.V()
z-=w+v
if(x>=y.length)return H.a(y,x)
y[x].cI(a,z)}},
fV:function(a){var z,y,x,w
for(z=this.cy,y=0;y<z.length;y=w){x=$.$get$o()
w=y+1
if(typeof x!=="number")return x.H()
z[y].i4(a,x*w)}},
cr:["ff",function(a){var z,y,x,w,v,u
z=J.m(a)
z.aI(a)
y=this.e
x=$.$get$O()
z.bf(a,J.d(y,x),this.f)
this.ct(a,this.z==null&&this.go)
y=this.Q===0
w=y&&this.z==null
this.dU(a,w,y&&this.y==null)
this.cs(a,this.y==null&&this.Q===0)
if(this.Q<=0)y=this.z!=null&&this.y!=null
else y=!0
if(y){y=this.e
w=this.f
z.B(a,y,J.d(w,this.r1?$.$get$o():this.x))
z.B(a,this.e,this.f)
z.B(a,J.d(this.e,x),this.f)}else if(this.y!=null){y=this.e
w=this.f
z.B(a,y,J.d(w,this.r1?$.$get$o():this.x))
z.B(a,this.e,J.d(this.f,x))
y=this.e
z.S(a,y,this.f,J.d(y,x),this.f)}else{y=this.z
w=this.e
v=this.f
if(y!=null){y=J.d(v,this.r1?$.$get$o():this.x)
v=this.e
u=this.f
z.S(a,w,y,v,J.r(J.d(u,this.r1?$.$get$o():this.x),x))
z.B(a,this.e,this.f)
z.B(a,J.d(this.e,x),this.f)}else{y=J.d(v,this.r1?$.$get$o():this.x)
v=this.e
u=this.f
z.S(a,w,y,v,J.r(J.d(u,this.r1?$.$get$o():this.x),x))
z.B(a,this.e,J.d(this.f,x))
y=this.e
z.S(a,y,this.f,J.d(y,x),this.f)}}z.cG(a)}],
dU:function(a,b,c){var z,y,x,w,v,u
z=$.$get$O()
y=J.m(a)
y.B(a,J.r(J.d(this.e,this.r),z),this.f)
if(b&&c){y.S(a,J.d(this.e,this.r),this.f,J.d(this.e,this.r),J.d(this.f,z))
x=J.d(this.e,this.r)
w=this.f
y.B(a,x,J.r(J.d(w,this.r1?$.$get$o():this.x),z))
x=J.d(this.e,this.r)
w=this.f
w=J.d(w,this.r1?$.$get$o():this.x)
v=J.r(J.d(this.e,this.r),z)
u=this.f
y.S(a,x,w,v,J.d(u,this.r1?$.$get$o():this.x))}else if(c){y.B(a,J.d(this.e,this.r),this.f)
x=J.d(this.e,this.r)
w=this.f
y.B(a,x,J.r(J.d(w,this.r1?$.$get$o():this.x),z))
x=J.d(this.e,this.r)
w=this.f
w=J.d(w,this.r1?$.$get$o():this.x)
v=J.r(J.d(this.e,this.r),z)
u=this.f
y.S(a,x,w,v,J.d(u,this.r1?$.$get$o():this.x))}else{x=this.e
w=this.r
if(b){y.S(a,J.d(x,w),this.f,J.d(this.e,this.r),J.d(this.f,z))
x=J.d(this.e,this.r)
w=this.f
y.B(a,x,J.d(w,this.r1?$.$get$o():this.x))
x=J.r(J.d(this.e,this.r),z)
w=this.f
y.B(a,x,J.d(w,this.r1?$.$get$o():this.x))}else{y.B(a,J.d(x,w),this.f)
x=J.d(this.e,this.r)
w=this.f
y.B(a,x,J.d(w,this.r1?$.$get$o():this.x))
x=J.r(J.d(this.e,this.r),z)
w=this.f
y.B(a,x,J.d(w,this.r1?$.$get$o():this.x))}}},
ct:function(a,b){var z,y,x,w,v
z=$.$get$O()
y=this.e
if(typeof z!=="number")return z.H()
y=J.d(y,z*2)
x=$.$get$aC()
w=this.gb9()
if(typeof x!=="number")return x.H()
v=J.d(y,x*w)
if(b){y=J.m(a)
y.B(a,v,this.f)
x=z/2
w=J.bh(v)
y.ed(a,v,J.d(this.f,x),w.v(v,z),J.d(this.f,x),w.v(v,z),this.f)}J.dn(a,J.r(J.d(this.e,this.r),z),this.f)},
cs:function(a,b){var z,y,x,w,v,u,t
z=$.$get$O()
y=this.e
if(typeof z!=="number")return z.H()
x=J.d(y,z*2)
if(!this.r1){y=$.$get$aC()
w=this.gaL()
if(typeof y!=="number")return y.H()
x=J.d(x,y*w)}if(b){y=J.bh(x)
w=y.v(x,z)
v=this.f
u=J.m(a)
u.B(a,w,J.d(v,this.r1?$.$get$o():this.x))
y=y.v(x,z)
v=this.f
w=z/2
v=J.d(J.d(v,this.r1?$.$get$o():this.x),w)
t=this.f
w=J.d(J.d(t,this.r1?$.$get$o():this.x),w)
t=this.f
u.ed(a,y,v,x,w,x,J.d(t,this.r1?$.$get$o():this.x))}y=J.r(x,z)
w=this.f
J.dn(a,y,J.d(w,this.r1?$.$get$o():this.x))},
bJ:function(a){var z,y,x,w,v,u
z=a.c
y=a.d
x=this.f
w=J.d(x,this.r1?$.$get$o():this.x)
v=this.e
if(typeof v!=="number")return H.l(v)
if(z>=v){if(typeof x!=="number")return H.l(x)
if(y>=x){u=this.r
if(typeof u!=="number")return H.l(u)
if(z<=v+u){if(typeof w!=="number")return H.l(w)
v=y<=w}else v=!1}else v=!1}else v=!1
return v},
ai:function(a){var z,y,x
this.id=!0
z=a.c
this.k1=z
y=a.d
this.k2=y
this.k3=z
this.k4=y
z=this.z
if(z!=null){z.sa_(null)
this.z=null}for(z=this.fy,x=this;x!=null;){z.hl(x)
z.aP(x)
x=x.gbO()}return this},
bn:function(a){var z
this.id=!1
this.r1=!1
this.r2=!1
z=this.fy
z.hD(this)
z.e1(this)
z.bh()},
bl:function(a){this.k1=a.c
this.k2=a.d},
bm:function(a){},
bp:function(a,b){var z=$.ah
$.ah=z+1
this.a=z
this.r=$.$get$ab()
this.x=$.$get$o()},
w:{
fZ:function(a,b){var z,y,x
z=[U.ak]
y=H.q([],z)
z=H.q([],z)
x=$.$get$V()
if(typeof x!=="number")return H.l(x)
x=new U.bp(null,b,null,null,0,0,0,0,null,null,0,null,y,z,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*x)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
x.bp(a,b)
return x},
du:function(a,b){var z,y,x,w,v,u,t,s,r,q
z=J.v(b)
y=z.h(b,"action")
x=y==null?"":J.C(y)
if(!!J.j(z.h(b,"clauses")).$ish){y=H.q([],[U.aD])
w=[U.ak]
v=H.q([],w)
u=H.q([],w)
t=$.$get$V()
if(typeof t!=="number")return H.l(t)
t=14*t
s=new U.aM(y,null,null,null,x,null,null,0,0,0,0,null,null,0,null,v,u,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(t)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
u=$.ah
$.ah=u+1
s.a=u
u=$.$get$ab()
s.r=u
v=$.$get$o()
s.x=v
t=new U.cz(null,null,null,"end-"+H.b(x),null,null,0,0,0,0,null,null,0,null,H.q([],w),H.q([],w),"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(t)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w=$.ah
$.ah=w+1
t.a=w
t.r=u
t.x=v
t.go=!1
if(typeof v!=="number")return v.aj()
t.x=v/2
t.d=""
s.x1=t
t.ry=s
y.push(t)
s.rx=s.x1}else{y=[U.ak]
if(J.J(z.h(b,"type"),"clause")){w=H.q([],y)
y=H.q([],y)
v=$.$get$V()
if(typeof v!=="number")return H.l(v)
s=new U.aD(null,null,null,x,null,null,0,0,0,0,null,null,0,null,w,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
v=$.ah
$.ah=v+1
s.a=v
s.r=$.$get$ab()
s.x=$.$get$o()
s.go=!1}else{w=H.q([],y)
y=H.q([],y)
v=$.$get$V()
if(typeof v!=="number")return H.l(v)
s=new U.bp(null,x,null,null,0,0,0,0,null,null,0,null,w,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
v=$.ah
$.ah=v+1
s.a=v
s.r=$.$get$ab()
s.x=$.$get$o()}}y=z.h(b,"type")
s.c=y==null?"":J.C(y)
y=z.h(b,"format")
s.d=y==null?null:J.C(y)
y=z.h(b,"blockColor")
w=s.db
s.db=y==null?w:J.C(y)
y=z.h(b,"textColor")
w=s.dx
s.dx=y==null?w:J.C(y)
y=z.h(b,"borderColor")
w=s.dy
s.dy=y==null?w:J.C(y)
y=z.h(b,"font")
w=s.fr
s.fr=y==null?w:J.C(y)
s.go=!U.ci(z.h(b,"start"),!1)
s.fx=U.ci(z.h(b,"required"),s.fx)
if(!!J.j(z.h(b,"params")).$ish)for(y=J.E(z.h(b,"params")),w=s.cx;y.m();)w.push(U.cN(s,y.gq()))
if(!!J.j(z.h(b,"properties")).$ish)for(y=J.E(z.h(b,"properties")),w=s.cy;y.m();)w.push(U.cN(s,y.gq()))
y=s.cy.length
w=$.$get$o()
if(typeof w!=="number")return H.l(w)
s.x=(1+y)*w
y=!!s.$isaM
if(y&&!!J.j(z.h(b,"clauses")).$ish)for(w=J.E(z.h(b,"clauses"));w.m();){r=w.gq()
J.aA(r,"type","clause")
q=H.cd(U.du(a,r),"$isaD")
H.cd(s,"$isaM").dk(q)}if(y&&z.h(b,"end")!=null){y=H.cd(s,"$isaM").x1
z=J.ag(z.h(b,"end"),"format")
y.d=z==null?null:J.C(z)}return s}}},
dC:{"^":"bp;cR:rx@",
gbO:function(){var z=this.y
if(z!=null)return z
else{z=this.rx
if(z!=null)return z
else{z=this.ch
if(z!=null)return z.rx
else return}}},
a7:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a7(a+this.gaL(),this)},
he:function(a){var z,y,x,w,v,u,t
z=$.$get$O()
if(this.rx!=null){y=this.e
x=$.$get$aC()
y=J.d(y,x)
w=this.f
w=J.d(w,this.r1?$.$get$o():this.x)
v=J.d(this.e,x)
u=this.f
t=J.m(a)
t.S(a,y,w,v,J.d(J.d(u,this.r1?$.$get$o():this.x),z))
y=this.y
w=this.e
if(y!=null){t.B(a,J.d(w,x),J.bl(this.rx))
t.B(a,J.d(J.d(this.e,x),z),J.bl(this.rx))}else{t.B(a,J.d(w,x),J.r(J.bl(this.rx),z))
t.S(a,J.d(this.e,x),J.bl(this.rx),J.d(J.d(this.e,x),z),J.bl(this.rx))}}}},
aD:{"^":"dC;hM:ry?,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gb9:function(){return 1},
gaL:function(){return 1},
gez:function(){return!1},
at:function(a){var z,y,x,w,v,u
z=this.fy
y=this.b
x=[U.ak]
w=H.q([],x)
x=H.q([],x)
v=$.$get$V()
if(typeof v!=="number")return H.l(v)
u=new U.aD(null,null,null,y,null,null,0,0,0,0,null,null,0,null,w,x,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,z,!0,!1,null,null,null,null,!1,!0)
u.bp(z,y)
u.go=!1
this.cc(u)
return u},
a6:function(a){var z,y
z=this.T()
z.l(0,"children",[])
J.ar(a,z)
y=this.y
if(y!=null)y.a6(z.h(0,"children"))},
cf:function(a){},
cd:function(a){},
ai:function(a){return this.ry.ai(a)}},
cz:{"^":"aD;ry,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gb9:function(){return 1},
gaL:function(){return 0},
a7:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a7(a,b)},
a6:function(a){J.ar(a,this.T())},
ce:function(a){}},
aM:{"^":"dC;ry,x1,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gb9:function(){return 0},
gaL:function(){return 1},
at:function(a){var z,y,x,w,v,u
z=U.fY(this.fy,this.b)
this.cc(z)
for(y=this.ry,x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=y[w]
u=J.j(v)
if(!u.$iscz)z.dk(u.at(v))}z.x1.d=this.x1.d
return z},
gb2:function(){var z,y
z=this.x1
y=z.y
return y!=null?y.gb2():z},
a6:function(a){var z,y,x,w
z=this.T()
z.l(0,"children",[])
z.l(0,"clauses",[])
J.ar(a,z)
y=this.y
if(y!=null)y.a6(z.h(0,"children"))
for(y=this.ry,x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)y[w].a6(z.h(0,"clauses"))
y=this.x1.y
if(y!=null)y.a6(a)},
a7:function(a,b){var z,y,x
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a7(a+1,this)
for(z=this.ry,y=z.length,x=0;x<z.length;z.length===y||(0,H.A)(z),++x)z[x].a7(a,b)},
b0:function(){var z,y,x,w,v,u,t,s
this.fg()
for(z=this.ry,y=z.length,x=this,w=0;w<z.length;z.length===y||(0,H.A)(z),++w,x=v){v=z[w]
u=J.m(v)
if(x.gb8()){t=x.ga_().gb2()
u.st(v,this.e)
s=t.f
u.su(v,J.d(s,t.r1?$.$get$o():t.x))}else{u.st(v,this.e)
s=J.m(x)
u.su(v,J.d(J.d(s.gu(x),s.gp(x)),$.$get$o()))}v.b0()}},
dk:function(a){var z,y,x,w
a.shM(this)
z=this.ry
C.a.A(z,this.x1)
z.push(a)
z.push(this.x1)
for(y=0;x=z.length,y<x-1;y=w){w=y+1
z[y].scR(z[w])}if(0>=x)return H.a(z,0)
this.rx=z[0]},
cr:function(a){var z,y,x,w,v,u,t,s,r,q
if(this.r1){this.ff(a)
return}z=$.$get$O()
y=J.m(a)
y.aI(a)
y.bf(a,J.d(this.e,z),this.f)
x=this.z==null&&this.go
for(w=this;w!=null;){if(!w.gb8())v=w.gcR()!=null||this.Q===0
else v=!1
w.ct(a,x)
w.dU(a,x,v)
w.cs(a,v)
w.he(a)
x=!w.gb8()
w=w.gcR()}u=this.x1
t=u.y!=null||this.Q>0
s=this.e
if(t){t=u.f
y.B(a,s,J.d(t,u.r1?$.$get$o():u.x))}else{u=J.d(s,z)
t=this.x1
s=t.f
y.B(a,u,J.d(s,t.r1?$.$get$o():t.x))
u=this.e
t=this.x1
s=t.f
t=J.d(s,t.r1?$.$get$o():t.x)
s=this.e
r=this.x1
q=r.f
y.S(a,u,t,s,J.r(J.d(q,r.r1?$.$get$o():r.x),z))}u=this.z
t=this.e
s=this.f
if(u!=null){y.B(a,t,s)
y.B(a,J.d(this.e,z),this.f)}else{y.B(a,t,J.d(s,z))
u=this.e
y.S(a,u,this.f,J.d(u,z),this.f)}y.cG(a)},
fu:function(a,b){var z,y,x,w
z="end-"+H.b(b)
y=[U.ak]
x=H.q([],y)
y=H.q([],y)
w=$.$get$V()
if(typeof w!=="number")return H.l(w)
w=new U.cz(null,null,null,z,null,null,0,0,0,0,null,null,0,null,x,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*w)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w.bp(a,z)
w.go=!1
z=$.$get$o()
if(typeof z!=="number")return z.aj()
w.x=z/2
w.d=""
this.x1=w
w.ry=this
this.ry.push(w)
this.rx=this.x1},
w:{
fY:function(a,b){var z,y,x,w
z=H.q([],[U.aD])
y=[U.ak]
x=H.q([],y)
y=H.q([],y)
w=$.$get$V()
if(typeof w!=="number")return H.l(w)
w=new U.aM(z,null,null,null,b,null,null,0,0,0,0,null,null,0,null,x,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*w)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w.bp(a,b)
w.fu(a,b)
return w}}},
ad:{"^":"e;a,b,P:c',d,e",
bK:function(a){var z,y
z=this.e
y=z.length
if(y===1){if(this.a.c!==this)a.k+="("
a.k+=H.b(this.b)+" "
if(0>=z.length)return H.a(z,0)
z[0].bK(a)
if(this.a.c!==this)a.k+=")"}else if(y===2){if(this.a.c!==this)a.k+="("
if(0>=y)return H.a(z,0)
z[0].bK(a)
a.k+=" "+H.b(this.b)+" "
if(1>=z.length)return H.a(z,1)
z[1].bK(a)
if(this.a.c!==this)a.k+=")"}else{z=this.b
if(z!=null)a.k+=H.b(z)}},
T:function(){var z,y,x,w,v
z=P.au(["name",this.b,"type",this.c])
y=this.e
if(y.length!==0){z.l(0,"children",[])
for(x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=y[w]
J.ar(z.h(0,"children"),v.T())}}y=this.d
if(y!=null)z.l(0,"format",y)
return z},
ax:function(a){var z,y,x,w,v
z=J.v(a)
y=z.h(a,"name")
this.b=y==null?"":J.C(y)
y=z.h(a,"type")
this.c=y==null?"num":J.C(y)
y=this.e
C.a.si(y,0)
if(!!J.j(z.h(a,"children")).$ish)for(z=J.E(z.h(a,"children")),x=[U.ad];z.m();){w=z.gq()
v=new U.ad(this.a,null,J.ag(w,"type"),null,H.q([],x))
y.push(v)
v.ax(w)}},
hO:function(a){var z,y,x,w
if(a==null)return this.e.length!==0
z=this.e
y=J.v(a)
if(z.length!==y.gi(a))return!0
x=0
while(!0){w=y.gi(a)
if(typeof w!=="number")return H.l(w)
if(!(x<w))break
w=y.h(a,x)
if(x>=z.length)return H.a(z,x)
if(!J.J(w,z[x].c))return!0;++x}return!1},
f8:function(a){var z,y,x,w,v,u,t
z=this.e
y=z.length===0
if(this.hO(a)){C.a.si(z,0)
if(a!=null){x=J.v(a)
w=[U.ad]
v=0
while(!0){u=x.gi(a)
if(typeof u!=="number")return H.l(u)
if(!(v<u))break
u=v===0&&y&&J.J(x.h(a,v),this.c)
t=this.a
if(u){u=new U.ad(t,null,x.h(a,v),null,H.q([],w))
u.b=this.b
z.push(u)}else z.push(new U.ad(t,null,x.h(a,v),null,H.q([],w)));++v}}}},
ec:function(a){var z,y
z=document.createElement("div")
C.b.ac(z,H.b(this.b))
z.classList.add("nt-expression-text")
z.classList.add("editable")
y=H.b(this.c)
z.classList.add(y)
W.K(z,"click",new U.hF(this,z),!1,W.U)
this.em(z,a)
a.appendChild(z)},
em:function(a,b){var z=W.U
W.K(a,"mouseenter",new U.hG(b),!1,z)
W.K(a,"mouseleave",new U.hH(b),!1,z)},
bH:function(a,b){var z=document.createElement("div")
C.b.ac(z,b?"(":")")
z.classList.add("nt-expression-text")
z.classList.add("parenthesis")
this.em(z,a)
a.appendChild(z)},
hK:function(a){var z,y
this.b=J.C(U.aq(this.b,0))
z=W.hT("number")
z.className="nt-number-input"
y=J.m(z)
y.sF(z,this.b)
y.sfe(z,"1")
y=y.gbQ(z)
W.K(y.a,y.b,new U.hE(this,z),!1,H.F(y,0))
a.appendChild(z)},
giu:function(){var z=this.b
if(z!=null)return P.fm(z,new U.hI())!=null
return!1},
bS:function(a){var z,y,x
z=document.createElement("div")
z.className="nt-expression"
if((this.giu()||this.b==null)&&J.J(this.c,"num"))this.hK(z)
else if(this.b==null){z.classList.add("empty")
C.b.az(z,"beforeend","<small>&#9660;</small>",null,null)}else{y=this.e
x=y.length
if(x===1){this.bH(z,!0)
this.ec(z)
if(0>=y.length)return H.a(y,0)
y[0].bS(z)
this.bH(z,!1)}else if(x===2){this.bH(z,!0)
if(0>=y.length)return H.a(y,0)
y[0].bS(z)
this.ec(z)
if(1>=y.length)return H.a(y,1)
y[1].bS(z)
this.bH(z,!1)}else C.b.az(z,"beforeend","<div class='nt-expression-text "+H.b(this.c)+"'>"+H.b(this.b)+"</div>",null,null)}if(this.e.length===0){z.classList.add("editable")
W.K(z,"click",new U.hL(this,z),!1,W.U)}a.appendChild(z)},
eG:function(a){var z,y,x,w
z=document
y=new W.af(z.querySelectorAll(".nt-pulldown-menu"),[null])
y.K(y,new U.hJ())
x=z.createElement("div")
x.classList.add("nt-pulldown-menu")
this.dm(x,this.a.a.cx)
if(J.fB(this.a.a.ch))C.b.az(x,"beforeend","<hr>",null,null)
this.dm(x,this.a.a.ch)
C.b.az(x,"beforeend","<hr>",null,null)
w=W.ds("#")
C.m.ac(w,"Clear")
w.className="clear"
x.appendChild(w)
W.K(w,"click",new U.hK(this,x),!1,W.U)
a.appendChild(x)},
dm:function(a,b){var z,y,x,w,v
for(z=J.E(b),y=W.U;z.m();){x=z.gq()
w=J.v(x)
if(J.J(w.h(x,"type"),this.c)){v=document.createElement("a")
v.href="#"
C.m.ac(v,H.b(w.h(x,"name")))
a.appendChild(v)
W.K(v,"click",new U.hD(this,a,x),!1,y)}}}},
hF:{"^":"f:0;a,b",
$1:function(a){this.a.eG(this.b)
J.bn(a)}},
hG:{"^":"f:0;a",
$1:function(a){this.a.classList.add("highlight")}},
hH:{"^":"f:0;a",
$1:function(a){this.a.classList.remove("highlight")}},
hE:{"^":"f:0;a,b",
$1:function(a){var z,y,x,w
z=this.a
y=this.b
x=J.m(y)
w=x.gF(y)
z.b=w
if(w===""){z.b="0"
x.sF(y,"0")}}},
hI:{"^":"f:0;",
$1:function(a){return}},
hL:{"^":"f:0;a,b",
$1:function(a){this.a.eG(this.b)
J.bn(a)}},
hJ:{"^":"f:0;",
$1:function(a){return J.bm(a)}},
hK:{"^":"f:0;a,b",
$1:function(a){var z
C.b.a3(this.b)
z=this.a
z.b=null
C.a.si(z.e,0)
z.a.cY()
z=J.m(a)
z.c0(a)
z.cX(a)}},
hD:{"^":"f:0;a,b,c",
$1:function(a){var z,y,x
C.b.a3(this.b)
z=this.a
y=this.c
x=J.v(y)
z.f8(x.h(y,"arguments"))
z.b=x.h(y,"name")
z.c=x.h(y,"type")
z.d=x.h(y,"format")
z.a.cY()
z=J.m(a)
z.c0(a)
z.cX(a)}},
cA:{"^":"e;a,b,c",
j:function(a){var z,y
z=new P.aH("")
this.c.bK(z)
y=z.k
return y.charCodeAt(0)==0?y:y},
ax:function(a){var z=J.j(a)
if(!!z.$isG)this.c.ax(a)
else if(a!=null)this.c.b=z.j(a)},
cY:function(){var z=this.b
if(z!=null&&this.c!=null){J.fz(z).a8(0)
this.c.bS(this.b)}}},
cu:{"^":"e;",
aX:function(a,b,c){var z,y
for(z=this.a,y=0;y<b;++y)a.k+=z
a.k+=c+"\n"},
aV:function(a,b,c){var z,y,x,w,v,u,t,s,r,q
z=J.v(b)
y=z.h(b,"format")
x=z.h(b,"params")
w=z.h(b,"properties")
v=J.j(x)
u=!!v.$ish?v.gi(x):0
t=J.j(w)
s=!!t.$ish?t.gi(w):0
if(typeof y!=="string"){y=H.b(z.h(b,"action"))
for(r=0;r<u;++r)y+=" {"+r+"}"
for(r=0;r<s;++r)y+=" {P"+r+"}"}for(r=0;r<u;++r){z="{"+r+"}"
q=this.dK(v.h(x,r))
if(typeof q!=="string")H.B(H.L(q))
y=H.dd(y,z,q)}for(r=0;r<s;++r){z="{P"+r+"}"
v=this.dK(t.h(w,r))
if(typeof v!=="string")H.B(H.L(v))
y=H.dd(y,z,v)}this.aX(a,c,y)},
dK:function(a){var z=J.v(a)
if(!!J.j(z.h(a,"value")).$isG)return this.aW(z.h(a,"value"))
else{z=z.h(a,"value")
return z==null?"":J.C(z)}},
aW:function(a){var z,y,x,w,v,u
z=J.v(a)
y=z.h(a,"children")
if(y==null||!J.j(y).$ish)y=[]
x=z.h(a,"name")
w=x==null?"":J.C(x)
x=z.h(a,"format")
if(typeof x==="string"){v=z.h(a,"format")
z=J.v(y)
u=0
while(!0){x=z.gi(y)
if(typeof x!=="number")return H.l(x)
if(!(u<x))break
v=J.fL(v,"{"+u+"}",this.aW(z.h(y,u)));++u}return v}else{z=J.v(y)
if(z.gi(y)===1)return"("+H.b(w)+" "+H.b(this.aW(z.h(y,0)))+")"
else if(z.gi(y)===2)return"("+H.b(this.aW(z.h(y,0)))+" "+H.b(w)+" "+H.b(this.aW(z.h(y,1)))+")"
else return w}}},
iU:{"^":"cu;a",
dJ:function(a){var z,y
z=new P.aH("")
for(y=J.E(a.h(0,"chains"));y.m();){this.ap(z,y.gq(),0)
z.k+="\n"}y=z.k
return y.charCodeAt(0)==0?y:y},
ap:function(a,b,c){var z,y,x,w,v,u
for(z=J.E(b),y=c+1;z.m();){x=z.gq()
this.aV(a,x,c)
w=J.v(x)
if(!!J.j(w.h(x,"children")).$ish)this.ap(a,w.h(x,"children"),y)
if(!!J.j(w.h(x,"clauses")).$ish)for(w=J.E(w.h(x,"clauses"));w.m();){v=w.gq()
this.aV(a,v,c)
u=J.v(v)
if(!!J.j(u.h(v,"children")).$ish)this.ap(a,u.h(v,"children"),y)}}}},
iJ:{"^":"cu;a",
dJ:function(a){var z,y,x,w
z=new P.aH("")
for(y=J.E(a.h(0,"chains"));y.m();){x=y.gq()
w=J.v(x)
if(J.az(w.gi(x),0)&&J.J(J.ag(w.h(x,0),"type"),"nlogo:procedure")){this.aV(z,w.ah(x,0),0)
this.ap(z,x,1)
w=z.k+="end\n"
z.k=w+"\n"}}y=z.k
return y.charCodeAt(0)==0?y:y},
ap:function(a,b,c){var z,y,x,w,v,u
for(z=J.E(b),y=c+1;z.m();){x=z.gq()
this.aV(a,x,c)
w=J.v(x)
if(!!J.j(w.h(x,"children")).$ish){this.aX(a,c,"[")
this.ap(a,w.h(x,"children"),y)
this.aX(a,c,"]")}if(!!J.j(w.h(x,"clauses")).$ish)for(w=J.E(w.h(x,"clauses"));w.m();){v=w.gq()
this.aV(a,v,c)
u=J.v(v)
if(!!J.j(u.h(v,"children")).$ish){this.aX(a,c,"[")
this.ap(a,u.h(v,"children"),y)
this.aX(a,c,"]")}}}}},
h_:{"^":"e;a,b,c,n:d>",
gt:function(a){return J.r(this.a.y,this.d)},
gu:function(a){return 0},
gp:function(a){return this.a.z},
bG:function(a){return!1},
iv:function(a){var z
if(!a.gdQ())if(!a.ge7()){z=J.m(a)
z=J.dg(J.d(z.gt(a),J.n(z.gn(a),0.75)),J.r(this.a.y,this.d))}else z=!1
else z=!1
return z},
eZ:function(a){var z,y,x,w
for(z=this.b,y=z.length,x=0;x<z.length;z.length===y||(0,H.A)(z),++x){w=z[x].a
if(J.J(w.b,a))return w}return},
bA:function(a){var z,y,x,w,v,u,t,s
z=$.$get$ab()
if(typeof z!=="number")return z.H()
this.d=z*1.5
for(z=this.b,y=z.length,x=0;x<z.length;z.length===y||(0,H.A)(z),++x){w=z[x]
v=this.d
u=w.a.dL(a)
t=$.$get$O()
if(typeof t!=="number")return t.H()
if(typeof u!=="number")return u.v()
s=$.$get$bM()
if(typeof s!=="number")return s.H()
this.d=Math.max(v,u+t*2+s*2)}},
cI:function(a,b){var z,y,x,w,v,u,t,s
this.bA(a)
z=J.m(a)
z.a0(a)
z.saw(a,this.c)
y=this.a
z.en(a,J.r(y.y,this.d),0,this.d,y.z)
if(b)z.en(a,J.r(y.y,this.d),0,this.d,y.z)
y=J.r(y.y,this.d)
x=$.$get$bM()
if(typeof x!=="number")return H.l(x)
w=y+x
x=$.$get$o()
if(typeof x!=="number")return x.aj()
v=0+x/2
for(y=this.b,u=y.length,t=0;t<y.length;y.length===u||(0,H.A)(y),++t){s=y[t]
s.b=w
s.c=v
s.i3(a)
v+=x*1.5}z.a4(a)}},
el:{"^":"e;a,t:b*,u:c*,d,e",
ey:function(){var z,y,x
z=this.e
y=J.a6(z)
x=y.V(z,this.d.bW(this.a.b))
return y.ak(z,0)||J.az(x,0)},
gn:function(a){return this.a.r},
gp:function(a){var z=this.a
return z.r1?$.$get$o():z.x},
i3:function(a){var z,y
z=this.a
J.r(this.e,this.d.bW(z.b))
y=J.m(a)
y.a0(a)
if(!this.ey())y.sf0(a,0.3)
z.e=this.b
z.f=this.c
z.bB(a,$.$get$ab())
z.cd(a)
z.ce(a)
z.cf(a)
y.a4(a)},
bJ:function(a){return this.a.bJ(a)},
ai:function(a){var z,y,x,w,v
if(this.ey()){z=this.a
y=z.at(0)
y.e=J.r(z.e,5)
y.f=J.r(z.f,5)
y.r2=!0
z=this.d
z.aP(y)
if(!!y.$isaM)for(x=y.ry,w=x.length,v=0;v<x.length;x.length===w||(0,H.A)(x),++v)z.aP(x[v])
return y.ai(a)}return this},
bn:function(a){},
bl:function(a){},
bm:function(a){}},
ak:{"^":"e;a,b,c,d,P:e',f,r,x,y,n:z>,p:Q>,ch",
gF:function(a){var z=this.c
return z==null?"":J.C(z)},
sF:function(a,b){var z=b==null?"":J.C(b)
this.c=z
return z},
gaO:function(a){return H.b(J.C(this.c))+H.b(this.r)},
b4:function(a,b){return U.cN(b,this.T())},
T:["dh",function(){return P.au(["type",this.e,"name",this.f,"unit",this.r,"value",this.gF(this),"default",this.d])}],
bA:function(a){var z,y,x
z=$.$get$O()
if(typeof z!=="number")return z.H()
this.z=z*2
z=J.m(a)
z.a0(a)
z.saK(a,this.b.fr)
y=this.z
x=z.cP(a,this.gaO(this)).width
if(typeof x!=="number")return H.l(x)
this.z=y+x
z.a4(a)},
hp:function(a){var z,y,x,w,v
this.bA(a)
z=this.z
y=J.m(a)
y.a0(a)
y.saK(a,this.b.fr)
x=$.$get$aC()
w=y.cP(a,"\u25b8    "+H.b(this.f)).width
if(typeof x!=="number")return x.v()
if(typeof w!=="number")return H.l(w)
v=$.$get$O()
if(typeof v!=="number")return v.H()
y.a4(a)
return z+(x+w+v*2)},
el:function(a,b,c){var z,y,x,w,v,u,t,s,r
this.x=b
this.y=c
z=this.b
y=J.m(a)
y.saK(a,z.fr)
y.sd3(a,"center")
y.sd4(a,"middle")
x=J.d(z.e,this.x)
w=J.d(z.f,this.y)
v=$.$get$o()
if(typeof v!=="number")return v.aj()
u=J.r(J.d(w,v/2),this.Q/2)
t=this.z
s=this.Q
y.aI(a)
v=s/2
y.aI(a)
w=J.bh(x)
y.bf(a,w.v(x,v),u)
y.B(a,J.r(w.v(x,t),v),u)
r=J.bh(u)
y.S(a,w.v(x,t),u,w.v(x,t),r.v(u,v))
y.B(a,w.v(x,t),J.r(r.v(u,s),v))
y.S(a,w.v(x,t),r.v(u,s),J.r(w.v(x,t),v),r.v(u,s))
y.B(a,w.v(x,v),r.v(u,s))
y.S(a,x,r.v(u,s),x,J.r(r.v(u,s),v))
y.B(a,x,r.v(u,v))
y.S(a,x,u,w.v(x,v),u)
y.cG(a)
y.saw(a,this.ch?z.db:z.dx)
y.cK(a)
y.saw(a,this.ch?z.dx:z.db)
y.cL(a,this.gaO(this),w.v(x,t/2),r.v(u,s*0.55))},
cI:function(a,b){return this.el(a,b,0)},
i4:function(a,b){var z,y,x,w,v,u,t,s
z=this.b
y=z.r
x=$.$get$O()
w=this.z
if(typeof x!=="number")return x.v()
if(typeof y!=="number")return y.V()
v=J.d(z.f,b)
u=$.$get$o()
if(typeof u!=="number")return u.aj()
t=J.d(v,u/2)
s=J.d(z.e,$.$get$aC())
u=J.m(a)
u.saw(a,z.dx)
u.saK(a,z.fr)
u.sd3(a,"left")
u.sd4(a,"middle")
u.cL(a,"\u25b8    "+H.b(this.f),s,t)
this.el(a,y-(x+w),b)},
bJ:function(a){var z,y,x
z=a.c
y=this.b
x=J.d(y.e,this.x)
if(typeof x!=="number")return H.l(x)
if(z>=x){z=a.d
x=J.d(y.f,this.y)
if(typeof x!=="number")return H.l(x)
if(z>=x){z=a.c
x=J.d(J.d(y.e,this.x),this.z)
if(typeof x!=="number")return H.l(x)
if(z<=x){z=a.d
y=J.d(J.d(y.f,this.y),$.$get$o())
if(typeof y!=="number")return H.l(y)
y=z<=y
z=y}else z=!1}else z=!1}else z=!1
return z},
bn:function(a){this.ch=!1
this.bE()
this.b.fy.X()},
ai:function(a){this.ch=!0
this.b.fy.X()
return this},
bl:function(a){},
bm:function(a){},
bE:function(){var z,y,x,w,v,u,t
z=document
y=z.createElement("div")
y.className="backdrop"
C.b.az(y,"beforeend",'      <div class="nt-param-dialog">\n        <div class="nt-param-table">\n          <div class="nt-param-row">'+this.ds()+'</div>\n        </div>\n        <button class="nt-param-confirm">OK</button>\n        <button class="nt-param-cancel">Cancel</button>\n      </div>',null,null)
x=z.querySelector("#"+H.b(this.b.fy.f)).parentElement
if(x==null)return
x.appendChild(y)
w=z.querySelector("#nt-param-label-"+this.a)
v=z.querySelector("#nt-param-"+this.a)
u=[null]
t=[W.U]
new W.aR(new W.af(z.querySelectorAll(".nt-param-confirm"),u),!1,"click",t).aA(new U.iQ(this,y,v))
new W.aR(new W.af(z.querySelectorAll(".nt-param-cancel"),u),!1,"click",t).aA(new U.iR(y))
y.classList.add("show")
if(v!=null){z=J.m(v)
z.eo(v)
if(w!=null){u=z.gbQ(v)
W.K(u.a,u.b,new U.iS(w,v),!1,H.F(u,0))
z=z.gcT(v)
W.K(z.a,z.b,new U.iT(w,v),!1,H.F(z,0))}}},
ds:function(){return'      <input class="nt-param-input" id="nt-param-'+this.a+'" type="text" value="'+this.gaO(this)+'">\n      <span class="nt-param-unit">'+H.b(this.r)+"</span>\n    "},
an:function(a,b){var z,y
z=$.e8
$.e8=z+1
this.a=z
z=J.v(b)
y=z.h(b,"type")
this.e=y==null?"num":J.C(y)
y=z.h(b,"name")
this.f=y==null?"":J.C(y)
y=z.h(b,"unit")
this.r=y==null?"":J.C(y)
z=z.h(b,"default")
this.d=z
this.sF(0,z)},
w:{
e7:function(a,b){var z=$.$get$o()
if(typeof z!=="number")return z.H()
z=new U.ak(null,a,null,null,"int","","",0,0,28,z*0.6,!1)
z.an(a,b)
return z},
cN:function(a,b){var z,y,x,w
z=J.v(b)
y=z.h(b,"type")
switch(y==null?"num":J.C(y)){case"int":y=$.$get$o()
if(typeof y!=="number")return y.H()
y=new U.hU(!1,1,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.an(a,b)
y.cx=U.ci(z.h(b,"random"),!1)
y.cy=U.aq(z.h(b,"step"),y.cy)
y.cy=1
return y
case"num":y=$.$get$o()
if(typeof y!=="number")return y.H()
y=new U.cB(null,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.an(a,b)
x=new U.cA(a.fy,null,null)
z=new U.ad(x,null,z.h(b,"type"),null,H.q([],[U.ad]))
x.c=z
y.cx=x
x=y.c
w=J.j(x)
if(!!w.$isG)z.ax(x)
else if(x!=null)z.b=w.j(x)
return y
case"bool":y=$.$get$o()
if(typeof y!=="number")return y.H()
y=new U.cB(null,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.an(a,b)
x=new U.cA(a.fy,null,null)
z=new U.ad(x,null,z.h(b,"type"),null,H.q([],[U.ad]))
x.c=z
y.cx=x
x=y.c
w=J.j(x)
if(!!w.$isG)z.ax(x)
else if(x!=null)z.b=w.j(x)
return y
case"range":y=$.$get$o()
if(typeof y!=="number")return y.H()
y=new U.j6(0,10,!1,1,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.an(a,b)
y.cx=U.ci(z.h(b,"random"),!1)
y.cy=U.aq(z.h(b,"step"),y.cy)
y.db=U.aq(z.h(b,"min"),y.db)
y.dx=U.aq(z.h(b,"max"),y.dx)
return y
case"select":return U.ej(a,b)
case"text":return U.e7(a,b)
default:return U.e7(a,b)}}}},
iQ:{"^":"f:0;a,b,c",
$1:[function(a){var z=this.c
if(z!=null)this.a.sF(0,J.bk(z))
C.b.a3(this.b)
z=this.a.b.fy
z.X()
z.bh()},null,null,2,0,null,0,"call"]},
iR:{"^":"f:0;a",
$1:[function(a){return C.b.a3(this.a)},null,null,2,0,null,0,"call"]},
iS:{"^":"f:0;a,b",
$1:function(a){J.cm(this.a,J.bk(this.b))}},
iT:{"^":"f:0;a,b",
$1:function(a){J.cm(this.a,J.bk(this.b))}},
e6:{"^":"ak;",
T:["fm",function(){var z=this.dh()
z.l(0,"random",this.cx)
z.l(0,"step",this.cy)
return z}],
gF:function(a){return U.aq(this.c,0)},
sF:function(a,b){var z=U.aq(b,0)
this.c=z
return z},
gaO:function(a){var z=J.fV(H.m2(this.gF(this)),1)
if(C.e.i7(z,".0"))z=C.e.am(z,0,z.length-2)
return z+H.b(this.r)},
ds:function(){return'      <div class="nt-param-name">'+H.b(this.f)+'</div>\n      <div class="nt-param-value">\n        <input class="nt-param-input" id="nt-param-'+this.a+'" type="number" step="'+H.b(this.cy)+'" value="'+H.b(this.gF(this))+'">\n        <span class="nt-param-unit">'+H.b(this.r)+"</span>\n      </div>\n    "}},
hU:{"^":"e6;cx,cy,a,b,c,d,e,f,r,x,y,z,Q,ch",
gF:function(a){return U.df(this.c,0)},
sF:function(a,b){var z=U.df(b,0)
this.c=z
return z}},
j6:{"^":"e6;db,dx,cx,cy,a,b,c,d,e,f,r,x,y,z,Q,ch",
T:function(){var z=this.fm()
z.l(0,"min",this.db)
z.l(0,"max",this.dx)
return z},
bE:function(){var z,y,x,w,v,u,t,s
z=document
y=z.createElement("div")
y.className="backdrop"
x=z.createElement("div")
x.className="nt-param-dialog"
w=z.createElement("div")
w.className="nt-param-table"
C.b.az(w,"beforeend",'        <div class="nt-param-row">\n          <div class="nt-param-label">\n            '+H.b(this.f)+':\n            <label id="nt-param-label-'+this.a+'" for="nt-param-'+this.a+'">'+H.b(U.aq(this.c,0))+'</label>\n            <span class="nt-param-unit">'+H.b(this.r)+'</span>\n          </div>\n        </div>\n        <div class="nt-param-row">\n          <div class="nt-param-value">\n            <input class="nt-param-input" id="nt-param-'+this.a+'" type="range" value="'+H.b(U.aq(this.c,0))+'" min="'+H.b(this.db)+'" max="'+H.b(this.dx)+'" step="'+H.b(this.cy)+'">\n          </div>\n        </div>\n      ',null,null)
x.appendChild(w)
v=W.U
W.K(x,"click",new U.j7(),!1,v)
y.appendChild(x)
W.K(y,"click",new U.j8(y),!1,v)
u=z.querySelector("#"+H.b(this.b.fy.f)).parentElement
if(u!=null)u.appendChild(y)
t=z.querySelector("#nt-param-label-"+this.a)
s=z.querySelector("#nt-param-"+this.a)
if(s!=null&&t!=null){z=J.m(s)
v=z.gbQ(s)
W.K(v.a,v.b,new U.j9(this,y,s),!1,H.F(v,0))
z=z.gcT(s)
W.K(z.a,z.b,new U.ja(t,s),!1,H.F(z,0))}y.classList.add("show")}},
j7:{"^":"f:0;",
$1:function(a){J.bn(a)}},
j8:{"^":"f:0;a",
$1:function(a){C.b.a3(this.a)}},
j9:{"^":"f:0;a,b,c",
$1:function(a){var z=this.a
z.c=U.aq(J.bk(this.c),0)
C.b.a3(this.b)
z=z.b.fy
z.X()
z.bh()
J.bn(a)}},
ja:{"^":"f:0;a,b",
$1:function(a){J.cm(this.a,J.bk(this.b))}},
jg:{"^":"ak;cx,a,b,c,d,e,f,r,x,y,z,Q,ch",
gaO:function(a){return H.b(J.C(this.c))+H.b(this.r)+" \u25be"},
b4:function(a,b){return U.ej(b,this.T())},
T:function(){var z=this.dh()
z.l(0,"values",this.cx)
return z},
bE:function(){var z,y,x,w,v,u,t,s,r,q,p
z=document
y=z.createElement("div")
y.className="backdrop"
x=z.createElement("div")
x.className="nt-param-dialog small"
w=z.createElement("div")
w.className="nt-param-table"
for(v=J.E(this.cx),u=W.U;v.m();){t=v.gq()
s=z.createElement("div")
s.className="nt-param-row"
r=z.createElement("div")
r.className="nt-select-option"
C.b.ac(r,t)
q=this.c
if(J.J(t,q==null?"":J.C(q)))r.classList.add("selected")
W.K(r,"click",new U.jh(this,y,t),!1,u)
s.appendChild(r)
w.appendChild(s)}x.appendChild(w)
y.appendChild(x)
W.K(y,"click",new U.ji(y),!1,u)
p=z.querySelector("#"+H.b(this.b.fy.f)).parentElement
if(p!=null)p.appendChild(y)
y.classList.add("show")},
fB:function(a,b){var z=J.v(b)
if(!!J.j(z.h(b,"values")).$ish&&J.az(J.a1(z.h(b,"values")),0)){z=z.h(b,"values")
this.cx=z
this.c=J.ag(z,0)}},
w:{
ej:function(a,b){var z=$.$get$o()
if(typeof z!=="number")return z.H()
z=new U.jg([],null,a,null,null,"int","","",0,0,28,z*0.6,!1)
z.an(a,b)
z.fB(a,b)
return z}}},
jh:{"^":"f:0;a,b,c",
$1:function(a){var z,y
z=this.a
y=this.c
z.c=y==null?"":J.C(y)
C.b.a3(this.b)
z=z.b.fy
z.X()
z.bh()
J.bn(a)}},
ji:{"^":"f:0;a",
$1:function(a){C.b.a3(this.a)}},
cB:{"^":"ak;cx,a,b,c,d,e,f,r,x,y,z,Q,ch",
gaO:function(a){var z=this.cx
return z!=null?z.j(0):""},
gF:function(a){return this.c},
sF:function(a,b){var z
this.c=b
z=this.cx
if(z!=null)z.ax(b)},
b4:function(a,b){return U.hu(b,this.T())},
bE:function(){var z,y,x,w,v,u,t
z=document
y=z.createElement("div")
y.className="backdrop"
C.b.az(y,"beforeend",'      <div class="nt-param-dialog">\n        <div class="nt-param-table">\n          <div class="nt-param-row">\n            <div class="nt-param-label">'+H.b(this.f)+':</div>\n          </div>\n          <div class="nt-param-row">\n            <div id="nt-expression-'+this.a+'" class="nt-expression-root"></div>\n          </div>\n        </div>\n        <button class="nt-param-confirm">OK</button>\n        <button class="nt-param-cancel">Cancel</button>\n      </div>',null,null)
x=z.querySelector("#"+H.b(this.b.fy.f)).parentElement
if(x==null)return
x.appendChild(y)
w=[null]
v=[W.U]
new W.aR(new W.af(z.querySelectorAll(".nt-param-confirm"),w),!1,"click",v).aA(new U.hy(this,y))
new W.aR(new W.af(z.querySelectorAll(".nt-param-confirm"),w),!1,"mousedown",v).aA(new U.hz())
new W.aR(new W.af(z.querySelectorAll(".nt-param-confirm"),w),!1,"mouseup",v).aA(new U.hA())
new W.aR(new W.af(z.querySelectorAll(".nt-param-cancel"),w),!1,"click",v).aA(new U.hB(y))
y.classList.add("show")
u=this.cx
t="#nt-expression-"+this.a
u.toString
u.b=z.querySelector(t)
u.cY()
new W.aR(new W.af(z.querySelectorAll(".nt-param-dialog"),w),!1,"click",v).aA(new U.hC())},
fz:function(a,b){var z=new U.cA(a.fy,null,null)
z.c=new U.ad(z,null,J.ag(b,"type"),null,H.q([],[U.ad]))
this.cx=z
z.ax(this.c)},
w:{
hu:function(a,b){var z=$.$get$o()
if(typeof z!=="number")return z.H()
z=new U.cB(null,null,a,null,null,"int","","",0,0,28,z*0.6,!1)
z.an(a,b)
z.fz(a,b)
return z}}},
hy:{"^":"f:0;a,b",
$1:[function(a){var z
if(document.querySelectorAll(".nt-expression.empty").length>0)return!1
z=this.a
z.c=z.cx.c.T()
C.b.a3(this.b)
z=z.b.fy
z.X()
z.bh()},null,null,2,0,null,0,"call"]},
hz:{"^":"f:0;",
$1:[function(a){var z=new W.af(document.querySelectorAll(".nt-expression.empty"),[null])
z.K(z,new U.hx())},null,null,2,0,null,0,"call"]},
hx:{"^":"f:0;",
$1:function(a){return J.cl(a).C(0,"warn")}},
hA:{"^":"f:0;",
$1:[function(a){var z=new W.af(document.querySelectorAll(".nt-expression.empty"),[null])
z.K(z,new U.hw())},null,null,2,0,null,0,"call"]},
hw:{"^":"f:0;",
$1:function(a){return J.cl(a).A(0,"warn")}},
hB:{"^":"f:0;a",
$1:[function(a){C.b.a3(this.a)},null,null,2,0,null,0,"call"]},
hC:{"^":"f:0;",
$1:[function(a){var z=new W.af(document.querySelectorAll(".nt-pulldown-menu"),[null])
z.K(z,new U.hv())},null,null,2,0,null,0,"call"]},
hv:{"^":"f:0;",
$1:function(a){return J.bm(a)}},
cv:{"^":"ev;f,r,x,n:y>,p:z>,Q,ch,cx,cy,db,a,b,c,d,e",
eR:function(){if(this.bG(0))this.X()
C.M.ghJ(window).eP(new U.h7(this))},
bh:function(){var z
this.X()
try{J.ag($.$get$d8(),"NetTango").bI("_relayCallback",[this.f])}catch(z){H.D(z)
P.cg("Unable to relay program changed event to Javascript")}},
b7:function(){var z,y,x,w,v,u,t,s
z=P.au(["chains",[]])
for(y=this.r,x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=y[w]
if(v.gez())J.ar(z.h(0,"chains"),v.b7())}for(y=this.Q.b,x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){u=y[w].a
if(u.fx)if(this.bW(u.b)===0){t=z.h(0,"chains")
s=[]
u.a6(s)
J.ar(t,s)}}return z},
aP:function(a){var z,y,x,w
this.r.push(a)
z=this.a
z.push(a)
for(y=a.geH(),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)z.push(y[w])
for(y=a.geJ(),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)z.push(y[w])},
hl:function(a){var z,y,x,w
C.a.A(this.r,a)
z=this.a
C.a.A(z,a)
for(y=a.geH(),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)C.a.A(z,y[w])
for(y=a.geJ(),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)C.a.A(z,y[w])
this.X()},
bW:function(a){var z,y,x,w
for(z=this.r,y=z.length,x=0,w=0;w<z.length;z.length===y||(0,H.A)(z),++w)if(J.J(J.fy(z[w]),a))++x
return x},
e1:function(a){var z,y,x
z=this.dI(a)
if(z!=null){y=z.ga_()
z.sa_(a)
a.z=z
if(y!=null){x=a.gb2()
y.sbR(x)
x.y=y}return!0}z=this.dH(a)
if(z!=null){z.sbR(a)
a.y=z
return!0}return!1},
hD:function(a){var z,y
if(this.Q.iv(a))for(z=this.r,y=this.a;a!=null;){C.a.A(z,a)
C.a.A(y,a)
a=a.gbO()}},
dI:function(a){var z,y,x,w,v,u,t,s,r
if(a.gbR()==null&&a.geu())for(z=this.r,y=z.length,x=J.m(a),w=0;w<z.length;z.length===y||(0,H.A)(z),++w){v=z[w]
u=J.j(v)
if(!u.G(v,a))if(J.b0(x.gt(a),J.d(u.gt(v),u.gn(v)))&&J.az(J.d(x.gt(a),x.gn(a)),u.gt(v))){t=u.gu(v)
s=J.d(u.gu(v),u.gp(v))
r=J.d(s,$.$get$O())
if(v.gb8()&&J.b0(a.gbk(),s)&&J.az(a.gbk(),t))return v
else if(!v.gb8()&&J.az(a.gbk(),t)&&J.b0(a.gbk(),r))return v}}return},
dH:function(a){var z,y,x,w,v,u
if(a.ga_()==null)for(z=this.r,y=z.length,x=J.m(a),w=0;w<z.length;z.length===y||(0,H.A)(z),++w){v=z[w]
u=J.j(v)
if(!u.G(v,a)&&v.gbR()==null&&v.geu())if(J.b0(x.gt(a),J.d(u.gt(v),u.gn(v)))&&J.az(J.d(x.gt(a),x.gn(a)),u.gt(v)))if(J.b0(J.fu(J.r(v.gbk(),a.gee())),20))return v}return},
bG:function(a){var z,y,x,w,v,u,t,s,r,q
this.Q.toString
for(z=this.r,y=z.length,x=!1,w=0,v=0;v<z.length;z.length===y||(0,H.A)(z),++v){u=z[v]
if(J.fw(u))x=!0
w=Math.max(H.bJ(u.gee()),w)}z=this.z
if(typeof z!=="number")return H.l(z)
if(w>z)if(!x){z=this.y
y=$.$get$V()
z=J.cj(z,y)
t=$.$get$o()
if(typeof t!=="number")return t.H()
if(typeof y!=="number")return H.l(y)
s=C.d.aB(z)
r=C.y.aB((w+t*3)/y)
t="#"+H.b(this.f)
q=document.querySelector(t)
if(q!=null){z=q.style
t=""+s+"px"
z.width=t
z=q.style
t=""+r+"px"
z.height=t
z=s*y
this.y=z
this.z=r*y
y=J.m(q)
y.sn(q,z)
y.sp(q,this.z)
this.cy=y.da(q,"2d")
this.X()}}return x},
X:function(){var z,y,x,w,v,u,t,s,r
J.fO(this.cy)
J.fx(this.cy,0,0,this.y,this.z)
z=H.q([],[U.bp])
for(y=this.r,x=y.length,w=!1,v=0;v<y.length;y.length===x||(0,H.A)(y),++v){u=y[v]
if(!u.ges()&&!(u instanceof U.aD)){u.a7(0,null)
u.b0()
u.bB(this.cy,$.$get$ab())}if(u.gdF())z.push(u)
t=this.Q
t.toString
if(!u.gdQ())if(!u.ge7()){s=J.m(u)
t=J.dg(J.d(s.gt(u),J.n(s.gn(u),0.75)),J.r(t.a.y,t.d))}else t=!1
else t=!1
if(t)w=!0}this.Q.cI(this.cy,w)
for(x=y.length,v=0;v<y.length;y.length===x||(0,H.A)(y),++v){u=y[v]
if(u.gdF()){r=this.dI(u)
if(r!=null)r.fT(this.cy)
else{r=this.dH(u)
if(r!=null)r.fW(this.cy)}}u.cd(this.cy)
u.ce(this.cy)
u.fU(this.cy)
u.fV(this.cy)
u.cf(this.cy)}J.fN(this.cy)},
hr:function(a){var z,y,x,w
z=J.v(a)
if(!!J.j(z.h(a,"chains")).$ish)for(z=J.E(z.h(a,"chains"));z.m();){y=z.gq()
x=J.j(y)
if(!!x.$ish)for(x=x.gE(y);x.m();){w=x.gq()
if(!!J.j(w).$isG)this.cv(w)}}},
cv:function(a){var z,y,x,w,v,u,t,s,r
z=J.v(a)
y=this.Q.eZ(z.h(a,"action"))
if(y!=null){x=y.at(0)
w=z.h(a,"x")
if(typeof w==="number"){w=z.h(a,"y")
w=typeof w==="number"}else w=!1
if(w){w=z.h(a,"x")
v=$.$get$cp()
x.e=J.n(w,v)
x.f=J.n(z.h(a,"y"),v)}this.aP(x)
if(!!x.$isaM)for(w=x.ry,v=w.length,u=0;u<w.length;w.length===v||(0,H.A)(w),++u)this.aP(w[u])
this.e1(x)
for(w=this.r,v=w.length,u=0;u<w.length;w.length===v||(0,H.A)(w),++u){t=w[u]
if(!t.ges()&&!(t instanceof U.aD)){t.a7(0,null)
t.b0()
t.bB(this.cy,$.$get$ab())}}this.hq(x,z.h(a,"params"),z.h(a,"properties"))
if(!!J.j(z.h(a,"children")).$ish)for(w=J.E(z.h(a,"children"));w.m();){s=w.gq()
if(!!J.j(s).$isG)this.cv(s)}if(!!J.j(z.h(a,"clauses")).$ish)for(z=J.E(z.h(a,"clauses"));z.m();){r=z.gq()
w=J.j(r)
if(!!w.$isG&&!!J.j(w.h(r,"children")).$ish)for(w=J.E(w.h(r,"children"));w.m();)this.cv(w.gq())}}},
hq:function(a,b,c){var z,y,x,w,v,u
z=J.j(b)
if(!!z.$ish)for(z=z.gE(b),y=a.cx,x=0;z.m();){w=z.gq()
v=J.j(w)
if(!!v.$isG&&w.N("value")===!0){if(x>=y.length)return H.a(y,x)
J.dq(y[x],v.h(w,"value"))}++x}z=J.j(c)
if(!!z.$ish)for(z=z.gE(c),y=a.cy,x=0;z.m();){u=z.gq()
v=J.j(u)
if(!!v.$isG&&u.N("value")===!0){if(x>=y.length)return H.a(y,x)
J.dq(y[x],v.h(u,"value"))}++x}},
fv:function(a,b){var z,y,x,w,v,u,t,s,r,q
z=this.f
y="#"+H.b(z)
x=document.querySelector(y)
if(x==null)throw H.c("No canvas element with ID "+H.b(z)+" found.")
z=J.m(x)
this.cy=z.da(x,"2d")
y=x.style
w=H.b(z.gn(x))+"px"
y.width=w
y=x.style
w=H.b(z.gp(x))+"px"
y.height=w
y=z.gn(x)
w=$.$get$V()
this.y=J.n(y,w)
this.z=J.n(z.gp(x),w)
z.sn(x,this.y)
z.sp(x,this.z)
if(typeof w!=="number")return H.l(w)
z=this.c
y=new U.bX([1,0,0,0,1,0,0,0,1])
y.a=[1/w,0,0,0,1/w,0,0,0,1]
z.iB(y)
this.d=this.c.is()
y=this.db
y.iG(x)
y.c.push(this)
y=H.q([],[U.el])
z=$.$get$ab()
w=$.$get$bM()
if(typeof w!=="number")return w.H()
if(typeof z!=="number")return z.v()
this.Q=new U.h_(this,y,"rgba(0,0,0, 0.2)",z+w*2)
z=this.x
y=J.v(z)
if(!!J.j(y.h(z,"blocks")).$ish)for(w=J.E(y.h(z,"blocks"));w.m();){v=w.gq()
u=U.du(this,v)
t=U.df(J.ag(v,"limit"),-1)
s=this.Q
r=s.b
s=s.a
q=new U.el(u,null,null,s,t)
u.r1=!0
s.a.push(q)
r.push(q)}if(!!J.j(y.h(z,"variables")).$ish)this.ch=y.h(z,"variables")
if(!!J.j(y.h(z,"expressions")).$ish)this.cx=y.h(z,"expressions")
if(!!J.j(y.h(z,"program")).$isG)this.hr(y.h(z,"program"))
this.X()
this.eR()},
w:{
dz:function(a,b){var z,y,x,w,v
z=H.q([],[U.bp])
y=H.q([],[U.ev])
x=P.y
w=U.jH
v=H.q([],[w])
z=new U.cv(a,z,b,null,null,null,[],[],null,new U.jB(!1,null,y,new H.a2(0,null,null,null,null,null,0,[x,U.eu])),v,new H.a2(0,null,null,null,null,null,0,[x,w]),new U.bX([1,0,0,0,1,0,0,0,1]),new U.bX([1,0,0,0,1,0,0,0,1]),new P.b4(Date.now(),!1))
z.fv(a,b)
return z}}},
h7:{"^":"f:0;a",
$1:function(a){return this.a.eR()}},
bX:{"^":"e;a",
is:function(){var z,y,x,w,v,u,t,s,r,q,p,o
z=[1,0,0,0,1,0,0,0,1]
y=new U.bX(z)
x=this.a
w=x.length
if(0>=w)return H.a(x,0)
v=x[0]
if(4>=w)return H.a(x,4)
u=x[4]
if(8>=w)return H.a(x,8)
u=J.n(u,x[8])
w=this.a
if(7>=w.length)return H.a(w,7)
t=J.n(v,J.r(u,J.n(w[7],w[5])))
w=this.a
u=w.length
if(3>=u)return H.a(w,3)
v=w[3]
s=w[1]
if(8>=u)return H.a(w,8)
w=J.n(s,w[8])
s=this.a
if(7>=s.length)return H.a(s,7)
r=J.n(v,J.r(w,J.n(s[7],s[2])))
s=this.a
if(6>=s.length)return H.a(s,6)
w=s[6]
s=J.n(s[1],s[5])
v=this.a
if(4>=v.length)return H.a(v,4)
q=J.n(w,J.r(s,J.n(v[4],v[2])))
p=J.d(J.r(t,r),q)
if(J.J(p,0))return y
if(typeof p!=="number")return H.l(p)
o=1/p
w=x.length
if(4>=w)return H.a(x,4)
v=x[4]
if(8>=w)return H.a(x,8)
v=J.n(v,x[8])
if(7>=x.length)return H.a(x,7)
v=J.r(v,J.n(x[7],x[5]))
if(typeof v!=="number")return H.l(v)
if(0>=z.length)return H.a(z,0)
z[0]=o*v
if(6>=x.length)return H.a(x,6)
v=J.n(x[6],x[5])
w=x.length
if(3>=w)return H.a(x,3)
u=x[3]
if(8>=w)return H.a(x,8)
u=J.r(v,J.n(u,x[8]))
if(typeof u!=="number")return H.l(u)
if(3>=z.length)return H.a(z,3)
z[3]=o*u
u=x.length
if(3>=u)return H.a(x,3)
v=x[3]
if(7>=u)return H.a(x,7)
v=J.n(v,x[7])
if(6>=x.length)return H.a(x,6)
v=J.r(v,J.n(x[6],x[4]))
if(typeof v!=="number")return H.l(v)
if(6>=z.length)return H.a(z,6)
z[6]=o*v
if(7>=x.length)return H.a(x,7)
v=J.n(x[7],x[2])
u=x.length
if(1>=u)return H.a(x,1)
w=x[1]
if(8>=u)return H.a(x,8)
w=J.r(v,J.n(w,x[8]))
if(typeof w!=="number")return H.l(w)
if(1>=z.length)return H.a(z,1)
z[1]=o*w
w=x.length
if(0>=w)return H.a(x,0)
v=x[0]
if(8>=w)return H.a(x,8)
v=J.n(v,x[8])
if(6>=x.length)return H.a(x,6)
v=J.r(v,J.n(x[6],x[2]))
if(typeof v!=="number")return H.l(v)
if(4>=z.length)return H.a(z,4)
z[4]=o*v
if(6>=x.length)return H.a(x,6)
v=J.n(x[6],x[1])
w=x.length
if(0>=w)return H.a(x,0)
u=x[0]
if(7>=w)return H.a(x,7)
u=J.r(v,J.n(u,x[7]))
if(typeof u!=="number")return H.l(u)
if(7>=z.length)return H.a(z,7)
z[7]=o*u
u=x.length
if(1>=u)return H.a(x,1)
v=x[1]
if(5>=u)return H.a(x,5)
v=J.n(v,x[5])
if(4>=x.length)return H.a(x,4)
v=J.r(v,J.n(x[4],x[2]))
if(typeof v!=="number")return H.l(v)
if(2>=z.length)return H.a(z,2)
z[2]=o*v
if(3>=x.length)return H.a(x,3)
v=J.n(x[3],x[2])
u=x.length
if(0>=u)return H.a(x,0)
w=x[0]
if(5>=u)return H.a(x,5)
w=J.r(v,J.n(w,x[5]))
if(typeof w!=="number")return H.l(w)
if(5>=z.length)return H.a(z,5)
z[5]=o*w
w=x.length
if(0>=w)return H.a(x,0)
v=x[0]
if(4>=w)return H.a(x,4)
v=J.n(v,x[4])
if(3>=x.length)return H.a(x,3)
v=J.r(v,J.n(x[3],x[1]))
if(typeof v!=="number")return H.l(v)
if(8>=z.length)return H.a(z,8)
z[8]=o*v
return y},
iB:function(a){var z,y,x,w,v,u
z=[1,0,0,0,1,0,0,0,1]
y=this.a
if(0>=y.length)return H.a(y,0)
y=y[0]
x=a.a
if(0>=x.length)return H.a(x,0)
x=J.n(y,x[0])
y=this.a
if(1>=y.length)return H.a(y,1)
y=y[1]
w=a.a
if(3>=w.length)return H.a(w,3)
w=J.d(x,J.n(y,w[3]))
y=this.a
if(2>=y.length)return H.a(y,2)
y=y[2]
x=a.a
if(6>=x.length)return H.a(x,6)
x=J.d(w,J.n(y,x[6]))
if(0>=z.length)return H.a(z,0)
z[0]=x
x=this.a
if(0>=x.length)return H.a(x,0)
x=x[0]
y=a.a
if(1>=y.length)return H.a(y,1)
y=J.n(x,y[1])
x=this.a
if(1>=x.length)return H.a(x,1)
x=x[1]
w=a.a
if(4>=w.length)return H.a(w,4)
w=J.d(y,J.n(x,w[4]))
x=this.a
if(2>=x.length)return H.a(x,2)
x=x[2]
y=a.a
if(7>=y.length)return H.a(y,7)
y=J.d(w,J.n(x,y[7]))
if(1>=z.length)return H.a(z,1)
z[1]=y
y=this.a
if(0>=y.length)return H.a(y,0)
y=y[0]
x=a.a
if(2>=x.length)return H.a(x,2)
x=J.n(y,x[2])
y=this.a
if(1>=y.length)return H.a(y,1)
y=y[1]
w=a.a
if(5>=w.length)return H.a(w,5)
w=J.d(x,J.n(y,w[5]))
y=this.a
if(2>=y.length)return H.a(y,2)
y=y[2]
x=a.a
if(8>=x.length)return H.a(x,8)
x=J.d(w,J.n(y,x[8]))
if(2>=z.length)return H.a(z,2)
z[2]=x
x=this.a
if(3>=x.length)return H.a(x,3)
x=x[3]
y=a.a
if(0>=y.length)return H.a(y,0)
y=J.n(x,y[0])
x=this.a
if(4>=x.length)return H.a(x,4)
x=x[4]
w=a.a
if(3>=w.length)return H.a(w,3)
w=J.d(y,J.n(x,w[3]))
x=this.a
if(5>=x.length)return H.a(x,5)
x=x[5]
y=a.a
if(6>=y.length)return H.a(y,6)
y=J.d(w,J.n(x,y[6]))
if(3>=z.length)return H.a(z,3)
z[3]=y
y=this.a
if(3>=y.length)return H.a(y,3)
y=y[3]
x=a.a
if(1>=x.length)return H.a(x,1)
x=J.n(y,x[1])
y=this.a
if(4>=y.length)return H.a(y,4)
y=y[4]
w=a.a
if(4>=w.length)return H.a(w,4)
w=J.d(x,J.n(y,w[4]))
y=this.a
if(5>=y.length)return H.a(y,5)
y=y[5]
x=a.a
if(7>=x.length)return H.a(x,7)
x=J.d(w,J.n(y,x[7]))
if(4>=z.length)return H.a(z,4)
z[4]=x
x=this.a
if(3>=x.length)return H.a(x,3)
x=x[3]
y=a.a
if(2>=y.length)return H.a(y,2)
y=J.n(x,y[2])
x=this.a
if(4>=x.length)return H.a(x,4)
x=x[4]
w=a.a
if(5>=w.length)return H.a(w,5)
w=J.d(y,J.n(x,w[5]))
x=this.a
if(5>=x.length)return H.a(x,5)
x=x[5]
y=a.a
if(8>=y.length)return H.a(y,8)
y=J.d(w,J.n(x,y[8]))
if(5>=z.length)return H.a(z,5)
z[5]=y
y=this.a
if(6>=y.length)return H.a(y,6)
y=y[6]
x=a.a
if(0>=x.length)return H.a(x,0)
x=J.n(y,x[0])
y=this.a
if(7>=y.length)return H.a(y,7)
y=y[7]
w=a.a
if(3>=w.length)return H.a(w,3)
w=J.d(x,J.n(y,w[3]))
y=this.a
if(8>=y.length)return H.a(y,8)
y=y[8]
x=a.a
if(6>=x.length)return H.a(x,6)
x=J.d(w,J.n(y,x[6]))
if(6>=z.length)return H.a(z,6)
z[6]=x
x=this.a
if(6>=x.length)return H.a(x,6)
x=x[6]
y=a.a
if(1>=y.length)return H.a(y,1)
y=J.n(x,y[1])
x=this.a
if(7>=x.length)return H.a(x,7)
x=x[7]
w=a.a
if(4>=w.length)return H.a(w,4)
w=J.d(y,J.n(x,w[4]))
x=this.a
if(8>=x.length)return H.a(x,8)
x=x[8]
y=a.a
if(7>=y.length)return H.a(y,7)
y=J.d(w,J.n(x,y[7]))
if(7>=z.length)return H.a(z,7)
z[7]=y
y=this.a
if(6>=y.length)return H.a(y,6)
y=y[6]
x=a.a
if(2>=x.length)return H.a(x,2)
x=J.n(y,x[2])
y=this.a
if(7>=y.length)return H.a(y,7)
y=y[7]
w=a.a
if(5>=w.length)return H.a(w,5)
w=J.d(x,J.n(y,w[5]))
y=this.a
if(8>=y.length)return H.a(y,8)
y=y[8]
x=a.a
if(8>=x.length)return H.a(x,8)
x=J.d(w,J.n(y,x[8]))
y=z.length
if(8>=y)return H.a(z,8)
z[8]=x
for(x=this.a,w=x.length,v=0;v<9;++v){if(v>=y)return H.a(z,v)
u=z[v]
if(v>=w)return H.a(x,v)
x[v]=u}},
aN:function(a){var z,y,x,w,v,u,t,s,r
z=a.c
y=this.a
x=y.length
if(0>=x)return H.a(y,0)
w=y[0]
if(typeof w!=="number")return H.l(w)
v=a.d
if(1>=x)return H.a(y,1)
u=y[1]
if(typeof u!=="number")return H.l(u)
if(2>=x)return H.a(y,2)
t=y[2]
if(typeof t!=="number")return H.l(t)
if(3>=x)return H.a(y,3)
s=y[3]
if(typeof s!=="number")return H.l(s)
if(4>=x)return H.a(y,4)
r=y[4]
if(typeof r!=="number")return H.l(r)
if(5>=x)return H.a(y,5)
y=y[5]
if(typeof y!=="number")return H.l(y)
a.c=z*w+v*u+t
a.d=z*s+v*r+y}},
jB:{"^":"e;a,b,c,d",
bL:function(a){var z,y,x
for(z=this.c,y=0;y<z.length;++y){x=z[y].bL(a)
if(x!=null){if(y>=z.length)return H.a(z,y)
z[y].e=new P.b4(Date.now(),!1)
if(y>=z.length)return H.a(z,y)
return new U.eu(z[y],x)}else if(y>=z.length)return H.a(z,y)}return},
iG:function(a){var z,y
this.b=a
z=J.m(a)
y=z.geD(a)
W.K(y.a,y.b,new U.jC(this),!1,H.F(y,0))
y=z.geF(a)
W.K(y.a,y.b,new U.jD(this),!1,H.F(y,0))
z=z.geE(a)
W.K(z.a,z.b,new U.jE(this),!1,H.F(z,0))
z=document
W.K(z,"keydown",new U.jF(this),!1,W.mX)
W.K(z,"touchmove",new U.jG(),!1,W.nQ)},
h9:function(a){var z,y
for(z=this.c.length,y=0;y<z;++y);}},
jC:{"^":"f:0;a",
$1:function(a){var z,y,x
z=this.a
y=U.cw(a)
x=z.bL(y)
if(x!=null)if(x.ai(y))z.d.l(0,-1,x)
z.a=!0
return}},
jD:{"^":"f:0;a",
$1:function(a){var z,y,x
z=this.a
y=z.d
x=y.h(0,-1)
if(x!=null)x.bn(U.cw(a))
y.l(0,-1,null)
z.a=!1
return}},
jE:{"^":"f:0;a",
$1:function(a){var z,y,x
z=this.a
y=U.cw(a)
x=z.d.h(0,-1)
if(x!=null)x.bl(y)
else{x=z.bL(y)
if(x!=null)if(z.a){x.a.d.aN(y)
x.b.bm(y)}}return}},
jF:{"^":"f:0;a",
$1:function(a){return this.a.h9(a)}},
jG:{"^":"f:0;",
$1:function(a){return J.fI(a)}},
ev:{"^":"e;",
bL:function(a){var z,y,x
z=new U.dB(null,-1,0,0,!1,!1,!1,!1,!1)
z.a=a.a
z.b=a.b
z.c=a.c
z.d=a.d
z.y=a.y
this.d.aN(z)
for(y=this.a,x=y.length-1;x>=0;--x){if(x>=y.length)return H.a(y,x)
if(y[x].bJ(z)){if(x>=y.length)return H.a(y,x)
return y[x]}}return}},
eu:{"^":"e;a,b",
ai:function(a){this.a.d.aN(a)
this.b=this.b.ai(a)
return!0},
bn:function(a){this.a.d.aN(a)
this.b.bn(a)},
bl:function(a){this.a.d.aN(a)
this.b.bl(a)},
bm:function(a){this.a.d.aN(a)
this.b.bm(a)}},
jH:{"^":"e;"},
dB:{"^":"e;a,b,c,d,e,f,r,x,y",
fw:function(a){var z,y
this.a=-1
z=J.m(a)
y=z.gbP(a)
y=y.gt(y)
y.toString
this.c=y
z=z.gbP(a)
z=z.gu(z)
z.toString
this.d=z
this.y=!0},
w:{
cw:function(a){var z=new U.dB(null,-1,0,0,!1,!1,!1,!1,!1)
z.fw(a)
return z}}}},1]]
setupProgram(dart,0)
J.j=function(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.dT.prototype
return J.dS.prototype}if(typeof a=="string")return J.bx.prototype
if(a==null)return J.ij.prototype
if(typeof a=="boolean")return J.ih.prototype
if(a.constructor==Array)return J.bv.prototype
if(typeof a!="object"){if(typeof a=="function")return J.by.prototype
return a}if(a instanceof P.e)return a
return J.cb(a)}
J.v=function(a){if(typeof a=="string")return J.bx.prototype
if(a==null)return a
if(a.constructor==Array)return J.bv.prototype
if(typeof a!="object"){if(typeof a=="function")return J.by.prototype
return a}if(a instanceof P.e)return a
return J.cb(a)}
J.aZ=function(a){if(a==null)return a
if(a.constructor==Array)return J.bv.prototype
if(typeof a!="object"){if(typeof a=="function")return J.by.prototype
return a}if(a instanceof P.e)return a
return J.cb(a)}
J.a6=function(a){if(typeof a=="number")return J.bw.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bD.prototype
return a}
J.bh=function(a){if(typeof a=="number")return J.bw.prototype
if(typeof a=="string")return J.bx.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bD.prototype
return a}
J.ca=function(a){if(typeof a=="string")return J.bx.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bD.prototype
return a}
J.m=function(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.by.prototype
return a}if(a instanceof P.e)return a
return J.cb(a)}
J.d=function(a,b){if(typeof a=="number"&&typeof b=="number")return a+b
return J.bh(a).v(a,b)}
J.cj=function(a,b){if(typeof a=="number"&&typeof b=="number")return a/b
return J.a6(a).aj(a,b)}
J.J=function(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.j(a).G(a,b)}
J.dg=function(a,b){if(typeof a=="number"&&typeof b=="number")return a>=b
return J.a6(a).bV(a,b)}
J.az=function(a,b){if(typeof a=="number"&&typeof b=="number")return a>b
return J.a6(a).bX(a,b)}
J.b0=function(a,b){if(typeof a=="number"&&typeof b=="number")return a<b
return J.a6(a).ak(a,b)}
J.n=function(a,b){if(typeof a=="number"&&typeof b=="number")return a*b
return J.bh(a).H(a,b)}
J.dh=function(a,b){return J.a6(a).fa(a,b)}
J.r=function(a,b){if(typeof a=="number"&&typeof b=="number")return a-b
return J.a6(a).V(a,b)}
J.fs=function(a,b){if(typeof a=="number"&&typeof b=="number")return(a^b)>>>0
return J.a6(a).ft(a,b)}
J.ag=function(a,b){if(typeof b==="number")if(a.constructor==Array||typeof a=="string"||H.fj(a,a[init.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.v(a).h(a,b)}
J.aA=function(a,b,c){if(typeof b==="number")if((a.constructor==Array||H.fj(a,a[init.dispatchPropertyName]))&&!a.immutable$list&&b>>>0===b&&b<a.length)return a[b]=c
return J.aZ(a).l(a,b,c)}
J.di=function(a){return J.m(a).fO(a)}
J.ft=function(a,b,c){return J.m(a).hn(a,b,c)}
J.fu=function(a){return J.a6(a).e8(a)}
J.ar=function(a,b){return J.aZ(a).C(a,b)}
J.fv=function(a,b,c,d){return J.m(a).e9(a,b,c,d)}
J.fw=function(a){return J.m(a).bG(a)}
J.fx=function(a,b,c,d,e){return J.m(a).hQ(a,b,c,d,e)}
J.dj=function(a,b){return J.m(a).b4(a,b)}
J.ck=function(a,b,c){return J.v(a).hS(a,b,c)}
J.b1=function(a,b){return J.aZ(a).J(a,b)}
J.fy=function(a){return J.m(a).gcC(a)}
J.dk=function(a){return J.m(a).ghL(a)}
J.fz=function(a){return J.m(a).gei(a)}
J.cl=function(a){return J.m(a).gcF(a)}
J.bj=function(a){return J.m(a).gav(a)}
J.a0=function(a){return J.j(a).gI(a)}
J.fA=function(a){return J.v(a).gD(a)}
J.fB=function(a){return J.v(a).gU(a)}
J.E=function(a){return J.aZ(a).gE(a)}
J.a1=function(a){return J.v(a).gi(a)}
J.fC=function(a){return J.m(a).giD(a)}
J.fD=function(a){return J.m(a).giE(a)}
J.dl=function(a){return J.m(a).gO(a)}
J.fE=function(a){return J.m(a).gd6(a)}
J.bk=function(a){return J.m(a).gF(a)}
J.dm=function(a){return J.m(a).gn(a)}
J.bl=function(a){return J.m(a).gu(a)}
J.fF=function(a){return J.m(a).d9(a)}
J.dn=function(a,b,c){return J.m(a).B(a,b,c)}
J.dp=function(a,b){return J.aZ(a).ag(a,b)}
J.fG=function(a,b,c){return J.ca(a).eA(a,b,c)}
J.fH=function(a,b){return J.j(a).cS(a,b)}
J.fI=function(a){return J.m(a).cX(a)}
J.bm=function(a){return J.aZ(a).a3(a)}
J.fJ=function(a,b){return J.aZ(a).A(a,b)}
J.fK=function(a,b,c,d){return J.m(a).eK(a,b,c,d)}
J.fL=function(a,b,c){return J.ca(a).iK(a,b,c)}
J.fM=function(a,b){return J.m(a).iL(a,b)}
J.fN=function(a){return J.m(a).a4(a)}
J.fO=function(a){return J.m(a).a0(a)}
J.b2=function(a,b){return J.m(a).bZ(a,b)}
J.fP=function(a,b){return J.m(a).shP(a,b)}
J.fQ=function(a,b){return J.m(a).sbM(a,b)}
J.cm=function(a,b){return J.m(a).sex(a,b)}
J.fR=function(a,b){return J.m(a).sP(a,b)}
J.dq=function(a,b){return J.m(a).sF(a,b)}
J.fS=function(a,b){return J.m(a).st(a,b)}
J.fT=function(a,b){return J.m(a).su(a,b)}
J.bn=function(a){return J.m(a).c0(a)}
J.dr=function(a){return J.a6(a).d5(a)}
J.fU=function(a){return J.ca(a).iP(a)}
J.C=function(a){return J.j(a).j(a)}
J.fV=function(a,b){return J.a6(a).iQ(a,b)}
J.cn=function(a){return J.ca(a).eS(a)}
I.aL=function(a){a.immutable$list=Array
a.fixed$length=Array
return a}
var $=I.p
C.m=W.fW.prototype
C.n=W.cr.prototype
C.b=W.hk.prototype
C.x=J.k.prototype
C.a=J.bv.prototype
C.y=J.dS.prototype
C.f=J.dT.prototype
C.d=J.bw.prototype
C.e=J.bx.prototype
C.F=J.by.prototype
C.t=J.iV.prototype
C.u=W.jt.prototype
C.l=J.bD.prototype
C.M=W.c3.prototype
C.v=new P.iP()
C.w=new P.k4()
C.c=new P.kR()
C.o=new P.aE(0)
C.z=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
C.A=function(hooks) {
  var userAgent = typeof navigator == "object" ? navigator.userAgent : "";
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
C.p=function(hooks) { return hooks; }

C.B=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var ua = navigator.userAgent;
    if (ua.indexOf("DumpRenderTree") >= 0) return hooks;
    if (ua.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
C.C=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (self.HTMLElement && object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof navigator == "object";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
C.D=function(hooks) {
  var userAgent = typeof navigator == "object" ? navigator.userAgent : "";
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
C.E=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
C.q=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
C.h=new P.iv(null,null)
C.G=new P.ix(null)
C.H=new P.iy(null,null)
C.I=H.q(I.aL(["*::class","*::dir","*::draggable","*::hidden","*::id","*::inert","*::itemprop","*::itemref","*::itemscope","*::lang","*::spellcheck","*::title","*::translate","A::accesskey","A::coords","A::hreflang","A::name","A::shape","A::tabindex","A::target","A::type","AREA::accesskey","AREA::alt","AREA::coords","AREA::nohref","AREA::shape","AREA::tabindex","AREA::target","AUDIO::controls","AUDIO::loop","AUDIO::mediagroup","AUDIO::muted","AUDIO::preload","BDO::dir","BODY::alink","BODY::bgcolor","BODY::link","BODY::text","BODY::vlink","BR::clear","BUTTON::accesskey","BUTTON::disabled","BUTTON::name","BUTTON::tabindex","BUTTON::type","BUTTON::value","CANVAS::height","CANVAS::width","CAPTION::align","COL::align","COL::char","COL::charoff","COL::span","COL::valign","COL::width","COLGROUP::align","COLGROUP::char","COLGROUP::charoff","COLGROUP::span","COLGROUP::valign","COLGROUP::width","COMMAND::checked","COMMAND::command","COMMAND::disabled","COMMAND::label","COMMAND::radiogroup","COMMAND::type","DATA::value","DEL::datetime","DETAILS::open","DIR::compact","DIV::align","DL::compact","FIELDSET::disabled","FONT::color","FONT::face","FONT::size","FORM::accept","FORM::autocomplete","FORM::enctype","FORM::method","FORM::name","FORM::novalidate","FORM::target","FRAME::name","H1::align","H2::align","H3::align","H4::align","H5::align","H6::align","HR::align","HR::noshade","HR::size","HR::width","HTML::version","IFRAME::align","IFRAME::frameborder","IFRAME::height","IFRAME::marginheight","IFRAME::marginwidth","IFRAME::width","IMG::align","IMG::alt","IMG::border","IMG::height","IMG::hspace","IMG::ismap","IMG::name","IMG::usemap","IMG::vspace","IMG::width","INPUT::accept","INPUT::accesskey","INPUT::align","INPUT::alt","INPUT::autocomplete","INPUT::autofocus","INPUT::checked","INPUT::disabled","INPUT::inputmode","INPUT::ismap","INPUT::list","INPUT::max","INPUT::maxlength","INPUT::min","INPUT::multiple","INPUT::name","INPUT::placeholder","INPUT::readonly","INPUT::required","INPUT::size","INPUT::step","INPUT::tabindex","INPUT::type","INPUT::usemap","INPUT::value","INS::datetime","KEYGEN::disabled","KEYGEN::keytype","KEYGEN::name","LABEL::accesskey","LABEL::for","LEGEND::accesskey","LEGEND::align","LI::type","LI::value","LINK::sizes","MAP::name","MENU::compact","MENU::label","MENU::type","METER::high","METER::low","METER::max","METER::min","METER::value","OBJECT::typemustmatch","OL::compact","OL::reversed","OL::start","OL::type","OPTGROUP::disabled","OPTGROUP::label","OPTION::disabled","OPTION::label","OPTION::selected","OPTION::value","OUTPUT::for","OUTPUT::name","P::align","PRE::width","PROGRESS::max","PROGRESS::min","PROGRESS::value","SELECT::autocomplete","SELECT::disabled","SELECT::multiple","SELECT::name","SELECT::required","SELECT::size","SELECT::tabindex","SOURCE::type","TABLE::align","TABLE::bgcolor","TABLE::border","TABLE::cellpadding","TABLE::cellspacing","TABLE::frame","TABLE::rules","TABLE::summary","TABLE::width","TBODY::align","TBODY::char","TBODY::charoff","TBODY::valign","TD::abbr","TD::align","TD::axis","TD::bgcolor","TD::char","TD::charoff","TD::colspan","TD::headers","TD::height","TD::nowrap","TD::rowspan","TD::scope","TD::valign","TD::width","TEXTAREA::accesskey","TEXTAREA::autocomplete","TEXTAREA::cols","TEXTAREA::disabled","TEXTAREA::inputmode","TEXTAREA::name","TEXTAREA::placeholder","TEXTAREA::readonly","TEXTAREA::required","TEXTAREA::rows","TEXTAREA::tabindex","TEXTAREA::wrap","TFOOT::align","TFOOT::char","TFOOT::charoff","TFOOT::valign","TH::abbr","TH::align","TH::axis","TH::bgcolor","TH::char","TH::charoff","TH::colspan","TH::headers","TH::height","TH::nowrap","TH::rowspan","TH::scope","TH::valign","TH::width","THEAD::align","THEAD::char","THEAD::charoff","THEAD::valign","TR::align","TR::bgcolor","TR::char","TR::charoff","TR::valign","TRACK::default","TRACK::kind","TRACK::label","TRACK::srclang","UL::compact","UL::type","VIDEO::controls","VIDEO::height","VIDEO::loop","VIDEO::mediagroup","VIDEO::muted","VIDEO::preload","VIDEO::width"]),[P.p])
C.J=I.aL(["HEAD","AREA","BASE","BASEFONT","BR","COL","COLGROUP","EMBED","FRAME","FRAMESET","HR","IMAGE","IMG","INPUT","ISINDEX","LINK","META","PARAM","SOURCE","STYLE","TITLE","WBR"])
C.i=I.aL([])
C.j=H.q(I.aL(["bind","if","ref","repeat","syntax"]),[P.p])
C.k=H.q(I.aL(["A::href","AREA::href","BLOCKQUOTE::cite","BODY::background","COMMAND::icon","DEL::cite","FORM::action","IMG::src","INPUT::src","INS::cite","Q::cite","VIDEO::poster"]),[P.p])
C.K=H.q(I.aL([]),[P.bC])
C.r=new H.hb(0,{},C.K,[P.bC,null])
C.L=new H.cR("call")
$.ec="$cachedFunction"
$.ed="$cachedInvocation"
$.ai=0
$.b3=null
$.dv=null
$.da=null
$.fc=null
$.fo=null
$.c9=null
$.ce=null
$.db=null
$.aU=null
$.bd=null
$.be=null
$.d4=!1
$.x=C.c
$.dM=0
$.at=null
$.cy=null
$.dL=null
$.dK=null
$.dI=null
$.dH=null
$.dG=null
$.dF=null
$.ah=0
$.bq=null
$.e8=0
$=null
init.isHunkLoaded=function(a){return!!$dart_deferred_initializers$[a]}
init.deferredInitialized=new Object(null)
init.isHunkInitialized=function(a){return init.deferredInitialized[a]}
init.initializeLoadedHunk=function(a){$dart_deferred_initializers$[a]($globals$,$)
init.deferredInitialized[a]=true}
init.deferredLibraryUris={}
init.deferredLibraryHashes={};(function(a){for(var z=0;z<a.length;){var y=a[z++]
var x=a[z++]
var w=a[z++]
I.$lazy(y,x,w)}})(["bO","$get$bO",function(){return H.d9("_$dart_dartClosure")},"cF","$get$cF",function(){return H.d9("_$dart_js")},"dP","$get$dP",function(){return H.ic()},"dQ","$get$dQ",function(){if(typeof WeakMap=="function")var z=new WeakMap()
else{z=$.dM
$.dM=z+1
z="expando$key$"+z}return new P.ht(null,z)},"ew","$get$ew",function(){return H.am(H.c2({
toString:function(){return"$receiver$"}}))},"ex","$get$ex",function(){return H.am(H.c2({$method$:null,
toString:function(){return"$receiver$"}}))},"ey","$get$ey",function(){return H.am(H.c2(null))},"ez","$get$ez",function(){return H.am(function(){var $argumentsExpr$='$arguments$'
try{null.$method$($argumentsExpr$)}catch(z){return z.message}}())},"eD","$get$eD",function(){return H.am(H.c2(void 0))},"eE","$get$eE",function(){return H.am(function(){var $argumentsExpr$='$arguments$'
try{(void 0).$method$($argumentsExpr$)}catch(z){return z.message}}())},"eB","$get$eB",function(){return H.am(H.eC(null))},"eA","$get$eA",function(){return H.am(function(){try{null.$method$}catch(z){return z.message}}())},"eG","$get$eG",function(){return H.am(H.eC(void 0))},"eF","$get$eF",function(){return H.am(function(){try{(void 0).$method$}catch(z){return z.message}}())},"cV","$get$cV",function(){return P.jO()},"bt","$get$bt",function(){var z,y
z=P.b8
y=new P.ao(0,P.jN(),null,[z])
y.fG(null,z)
return y},"bf","$get$bf",function(){return[]},"eR","$get$eR",function(){return P.dW(["A","ABBR","ACRONYM","ADDRESS","AREA","ARTICLE","ASIDE","AUDIO","B","BDI","BDO","BIG","BLOCKQUOTE","BR","BUTTON","CANVAS","CAPTION","CENTER","CITE","CODE","COL","COLGROUP","COMMAND","DATA","DATALIST","DD","DEL","DETAILS","DFN","DIR","DIV","DL","DT","EM","FIELDSET","FIGCAPTION","FIGURE","FONT","FOOTER","FORM","H1","H2","H3","H4","H5","H6","HEADER","HGROUP","HR","I","IFRAME","IMG","INPUT","INS","KBD","LABEL","LEGEND","LI","MAP","MARK","MENU","METER","NAV","NOBR","OL","OPTGROUP","OPTION","OUTPUT","P","PRE","PROGRESS","Q","S","SAMP","SECTION","SELECT","SMALL","SOURCE","SPAN","STRIKE","STRONG","SUB","SUMMARY","SUP","TABLE","TBODY","TD","TEXTAREA","TFOOT","TH","THEAD","TIME","TR","TRACK","TT","U","UL","VAR","VIDEO","WBR"],null)},"cZ","$get$cZ",function(){return P.bA()},"dE","$get$dE",function(){return P.je("^\\S+$",!0,!1)},"d8","$get$d8",function(){return P.fa(self)},"cX","$get$cX",function(){return H.d9("_$dart_dartObject")},"d1","$get$d1",function(){return function DartObject(a){this.o=a}},"V","$get$V",function(){return W.mb().devicePixelRatio},"ab","$get$ab",function(){var z=$.$get$V()
if(typeof z!=="number")return H.l(z)
return 80*z},"o","$get$o",function(){var z=$.$get$V()
if(typeof z!=="number")return H.l(z)
return 34*z},"O","$get$O",function(){var z=$.$get$V()
if(typeof z!=="number")return H.l(z)
return 10*z},"aC","$get$aC",function(){var z=$.$get$V()
if(typeof z!=="number")return H.l(z)
return 25*z},"bM","$get$bM",function(){var z=$.$get$V()
if(typeof z!=="number")return H.l(z)
return 10*z},"cp","$get$cp",function(){return $.$get$O()},"S","$get$S",function(){return P.bA()}])
I=I.$finishIsolateConstructor(I)
$=new I()
init.metadata=["e",null,"value","canvasId","error","_","stackTrace","attributeName","invocation","object","x","data","element","context","o","jsonString","arg1","arg2","arg3","each","sender","arg4","isolate","arg","language","time","attr","n","callback","captureThis","self","arguments","numberOfArguments","closure"]
init.types=[{func:1,args:[,]},{func:1,v:true},{func:1},{func:1,v:true,args:[P.e],opt:[P.bB]},{func:1,v:true,args:[{func:1,v:true}]},{func:1,args:[,,]},{func:1,ret:P.p,args:[P.y]},{func:1,args:[P.aO]},{func:1,ret:P.bI,args:[W.N,P.p,P.p,W.cY]},{func:1,args:[P.p,,]},{func:1,args:[,P.p]},{func:1,args:[P.p]},{func:1,args:[{func:1,v:true}]},{func:1,args:[,],opt:[,]},{func:1,v:true,args:[,P.bB]},{func:1,args:[P.bC,,]},{func:1,args:[W.N]},{func:1,args:[P.bI,P.aO]},{func:1,v:true,args:[W.t,W.t]},{func:1,v:true,args:[P.e]},{func:1,ret:P.y,args:[P.p]},{func:1,ret:P.ap,args:[P.p]},{func:1,ret:P.e,args:[,]},{func:1,v:true,args:[P.p,P.p]},{func:1,v:true,args:[P.p]},{func:1,ret:P.p,args:[P.p,P.p]},{func:1,ret:P.p,args:[P.p]},{func:1,ret:P.p}]
function convertToFastObject(a){function MyClass(){}MyClass.prototype=a
new MyClass()
return a}function convertToSlowObject(a){a.__MAGIC_SLOW_PROPERTY=1
delete a.__MAGIC_SLOW_PROPERTY
return a}A=convertToFastObject(A)
B=convertToFastObject(B)
C=convertToFastObject(C)
D=convertToFastObject(D)
E=convertToFastObject(E)
F=convertToFastObject(F)
G=convertToFastObject(G)
H=convertToFastObject(H)
J=convertToFastObject(J)
K=convertToFastObject(K)
L=convertToFastObject(L)
M=convertToFastObject(M)
N=convertToFastObject(N)
O=convertToFastObject(O)
P=convertToFastObject(P)
Q=convertToFastObject(Q)
R=convertToFastObject(R)
S=convertToFastObject(S)
T=convertToFastObject(T)
U=convertToFastObject(U)
V=convertToFastObject(V)
W=convertToFastObject(W)
X=convertToFastObject(X)
Y=convertToFastObject(Y)
Z=convertToFastObject(Z)
function init(){I.p=Object.create(null)
init.allClasses=map()
init.getTypeFromName=function(a){return init.allClasses[a]}
init.interceptorsByTag=map()
init.leafTags=map()
init.finishedClasses=map()
I.$lazy=function(a,b,c,d,e){if(!init.lazies)init.lazies=Object.create(null)
init.lazies[a]=b
e=e||I.p
var z={}
var y={}
e[a]=z
e[b]=function(){var x=this[a]
if(x==y)H.m9(d||a)
try{if(x===z){this[a]=y
try{x=this[a]=c()}finally{if(x===z)this[a]=null}}return x}finally{this[b]=function(){return this[a]}}}}
I.$finishIsolateConstructor=function(a){var z=a.p
function Isolate(){var y=Object.keys(z)
for(var x=0;x<y.length;x++){var w=y[x]
this[w]=z[w]}var v=init.lazies
var u=v?Object.keys(v):[]
for(var x=0;x<u.length;x++)this[v[u[x]]]=null
function ForceEfficientMap(){}ForceEfficientMap.prototype=this
new ForceEfficientMap()
for(var x=0;x<u.length;x++){var t=v[u[x]]
this[t]=z[t]}}Isolate.prototype=a.prototype
Isolate.prototype.constructor=Isolate
Isolate.p=z
Isolate.aL=a.aL
Isolate.R=a.R
return Isolate}}!function(){var z=function(a){var t={}
t[a]=1
return Object.keys(convertToFastObject(t))[0]}
init.getIsolateTag=function(a){return z("___dart_"+a+init.isolateTag)}
var y="___dart_isolate_tags_"
var x=Object[y]||(Object[y]=Object.create(null))
var w="_ZxYxX"
for(var v=0;;v++){var u=z(w+"_"+v+"_")
if(!(u in x)){x[u]=1
init.isolateTag=u
break}}init.dispatchPropertyName=init.getIsolateTag("dispatch_record")}();(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!='undefined'){a(document.currentScript)
return}var z=document.scripts
function onLoad(b){for(var x=0;x<z.length;++x)z[x].removeEventListener("load",onLoad,false)
a(b.target)}for(var y=0;y<z.length;++y)z[y].addEventListener("load",onLoad,false)})(function(a){init.currentScript=a
if(typeof dartMainRunner==="function")dartMainRunner(function(b){H.fq(U.fl(),b)},[])
else (function(b){H.fq(U.fl(),b)})([])})})()/*
 * NetTango
 * Copyright (c) 2017 Michael S. Horn, Uri Wilensky, and Corey Brady
 * 
 * Northwestern University
 * 2120 Campus Drive
 * Evanston, IL 60613
 * http://tidal.northwestern.edu
 * http://ccl.northwestern.edu
 
 * This project was funded in part by the National Science Foundation.
 * Any opinions, findings and conclusions or recommendations expressed in this
 * material are those of the author(s) and do not necessarily reflect the views
 * of the National Science Foundation (NSF).
 */

/**
 * NetTango functions can be used to create a blocks-based programming interface
 * associated with an HTML canvas. 
 */
var NetTango = {


  /// Call init to instantiate a workspace associated with an HTML canvas. 
  /// TODO: Document JSON specification format--for now see README.md
  init : function(canvasId, json) {
    NetTango_InitWorkspace(canvasId, JSON.stringify(json));
  },


  /// Add a callback function to receive programChanged events from the 
  /// workspace. Callback functions should take one parameter, which is 
  /// the canvasId for the workspace (as a String).
  onProgramChanged : function(canvasId, callback) {
    NetTango._callbacks[canvasId] = callback;
  },


  /// Exports the code for a workspace in a given target language. 
  /// The only language supported now is "NetLogo".
  exportCode : function(canvasId, language) {
    return NetTango_ExportCode(canvasId, language);
  },


  /// Exports the current state of the workspace as a JSON object to be 
  /// restored at a later point.
  save : function(canvasId) {
    return JSON.parse(NetTango_Save(canvasId));
  },


  /// Exports the state of all workspaces as a JSON object to be restored
  /// at a later point.
  saveAll : function() {
    return JSON.parse(NetTango_SaveAll());
  },


  /// Restores a workspace to a previously saved state (json object). 
  /// Note, for now this is just an alias of the NetTango.init function.
  restore : function(canvasId, json) {
    NetTango_InitWorkspace(canvasId, JSON.stringify(json));
  },


  /// Restores all workspaces from a previously saved state.
  restoreAll : function(json) {
    NetTango_InitAllWorkspaces(JSON.stringify(json));
  },


  _relayCallback : function(canvasId) {
    if (canvasId in NetTango._callbacks) {
      NetTango._callbacks[canvasId](canvasId);
    }
  },

  _callbacks : { }
}