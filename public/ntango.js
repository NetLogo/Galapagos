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
if(a7)b6[b4+"*"]=d[0]}}function tearOffGetter(c,d,e,f){return f?new Function("funcs","reflectionInfo","name","H","c","return function tearOff_"+e+y+++"(x) {"+"if (c === null) c = "+"H.d6"+"("+"this, funcs, reflectionInfo, false, [x], name);"+"return new c(this, funcs[0], x, name);"+"}")(c,d,e,H,null):new Function("funcs","reflectionInfo","name","H","c","return function tearOff_"+e+y+++"() {"+"if (c === null) c = "+"H.d6"+"("+"this, funcs, reflectionInfo, false, [], name);"+"return new c(this, funcs[0], null, name);"+"}")(c,d,e,H,null)}function tearOff(c,d,e,f,a0){var g
return e?function(){if(g===void 0)g=H.d6(this,c,d,true,[],f).prototype
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
x.push([p,o,i,h,n,j,k,m])}finishClasses(s)}I.Q=function(){}
var dart=[["","",,H,{"^":"",mQ:{"^":"e;a"}}],["","",,J,{"^":"",
j:function(a){return void 0},
ce:function(a,b,c,d){return{i:a,p:b,e:c,x:d}},
ca:function(a){var z,y,x,w,v
z=a[init.dispatchPropertyName]
if(z==null)if($.da==null){H.lK()
z=a[init.dispatchPropertyName]}if(z!=null){y=z.p
if(!1===y)return z.i
if(!0===y)return a
x=Object.getPrototypeOf(a)
if(y===x)return z.i
if(z.e===x)throw H.c(new P.cS("Return interceptor for "+H.b(y(a,z))))}w=a.constructor
v=w==null?null:w[$.$get$cE()]
if(v!=null)return v
v=H.lU(a)
if(v!=null)return v
if(typeof a=="function")return C.F
y=Object.getPrototypeOf(a)
if(y==null)return C.t
if(y===Object.prototype)return C.t
if(typeof w=="function"){Object.defineProperty(w,$.$get$cE(),{value:C.l,enumerable:false,writable:true,configurable:true})
return C.l}return C.l},
k:{"^":"e;",
F:function(a,b){return a===b},
gI:function(a){return H.ax(a)},
j:["fh",function(a){return H.bZ(a)}],
cR:["fg",function(a,b){throw H.c(P.e0(a,b.geA(),b.geH(),b.geB(),null))},null,"giC",2,0,null,8],
"%":"CanvasGradient|CanvasPattern|Client|DOMError|DOMImplementation|FileError|MediaError|NavigatorUserMediaError|PositionError|PushMessageData|SQLError|SVGAnimatedEnumeration|SVGAnimatedLength|SVGAnimatedLengthList|SVGAnimatedNumber|SVGAnimatedNumberList|SVGAnimatedString|WebGLRenderingContext|WindowClient"},
ih:{"^":"k;",
j:function(a){return String(a)},
gI:function(a){return a?519018:218159},
$isbF:1},
ij:{"^":"k;",
F:function(a,b){return null==b},
j:function(a){return"null"},
gI:function(a){return 0},
cR:[function(a,b){return this.fg(a,b)},null,"giC",2,0,null,8]},
cF:{"^":"k;",
gI:function(a){return 0},
j:["fj",function(a){return String(a)}],
$isik:1},
iV:{"^":"cF;"},
bA:{"^":"cF;"},
bw:{"^":"cF;",
j:function(a){var z=a[$.$get$bM()]
return z==null?this.fj(a):J.C(z)},
$iscB:1,
$S:function(){return{func:1,opt:[,,,,,,,,,,,,,,,,]}}},
bt:{"^":"k;$ti",
eg:function(a,b){if(!!a.immutable$list)throw H.c(new P.u(b))},
b3:function(a,b){if(!!a.fixed$length)throw H.c(new P.u(b))},
C:function(a,b){this.b3(a,"add")
a.push(b)},
ag:function(a,b){var z
this.b3(a,"removeAt")
z=a.length
if(b>=z)throw H.c(P.b9(b,null,null))
return a.splice(b,1)[0]},
A:function(a,b){var z
this.b3(a,"remove")
for(z=0;z<a.length;++z)if(J.J(a[z],b)){a.splice(z,1)
return!0}return!1},
V:function(a,b){var z
this.b3(a,"addAll")
for(z=J.E(b);z.n();)a.push(z.gt())},
J:function(a,b){var z,y
z=a.length
for(y=0;y<z;++y){b.$1(a[y])
if(a.length!==z)throw H.c(new P.a7(a))}},
af:function(a,b){return new H.b6(a,b,[H.F(a,0),null])},
ib:function(a,b,c){var z,y,x
z=a.length
for(y=!1,x=0;x<z;++x){y=c.$2(y,a[x])
if(a.length!==z)throw H.c(new P.a7(a))}return y},
L:function(a,b){if(b>>>0!==b||b>=a.length)return H.a(a,b)
return a[b]},
gia:function(a){if(a.length>0)return a[0]
throw H.c(H.cD())},
X:function(a,b,c,d,e){var z,y,x
this.eg(a,"setRange")
P.cO(b,c,a.length,null,null,null)
z=c-b
if(z===0)return
if(e<0)H.B(P.G(e,0,null,"skipCount",null))
if(e+z>d.length)throw H.c(H.dQ())
if(e<b)for(y=z-1;y>=0;--y){x=e+y
if(x<0||x>=d.length)return H.a(d,x)
a[b+y]=d[x]}else for(y=0;y<z;++y){x=e+y
if(x<0||x>=d.length)return H.a(d,x)
a[b+y]=d[x]}},
ea:function(a,b){var z,y
z=a.length
for(y=0;y<z;++y){if(b.$1(a[y])===!0)return!0
if(a.length!==z)throw H.c(new P.a7(a))}return!1},
K:function(a,b){var z
for(z=0;z<a.length;++z)if(J.J(a[z],b))return!0
return!1},
gD:function(a){return a.length===0},
gT:function(a){return a.length!==0},
j:function(a){return P.bQ(a,"[","]")},
gH:function(a){return new J.co(a,a.length,0,null)},
gI:function(a){return H.ax(a)},
gi:function(a){return a.length},
si:function(a,b){this.b3(a,"set length")
if(b<0)throw H.c(P.G(b,0,null,"newLength",null))
a.length=b},
h:function(a,b){if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(H.M(a,b))
if(b>=a.length||b<0)throw H.c(H.M(a,b))
return a[b]},
l:function(a,b,c){this.eg(a,"indexed set")
if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(H.M(a,b))
if(b>=a.length||b<0)throw H.c(H.M(a,b))
a[b]=c},
$isS:1,
$asS:I.Q,
$ish:1,
$ash:null,
$isi:1,
$asi:null},
mP:{"^":"bt;$ti"},
co:{"^":"e;a,b,c,d",
gt:function(){return this.d},
n:function(){var z,y,x
z=this.a
y=z.length
if(this.b!==y)throw H.c(H.A(z))
x=this.c
if(x>=y){this.d=null
return!1}this.d=z[x]
this.c=x+1
return!0}},
bu:{"^":"k;",
git:function(a){return a===0?1/a<0:a<0},
e7:function(a){return Math.abs(a)},
d4:function(a){var z
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){z=a<0?Math.ceil(a):Math.floor(a)
return z+0}throw H.c(new P.u(""+a+".toInt()"))},
aA:function(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw H.c(new P.u(""+a+".round()"))},
iQ:function(a,b){var z
if(b>20)throw H.c(P.G(b,0,20,"fractionDigits",null))
z=a.toFixed(b)
if(a===0&&this.git(a))return"-"+z
return z},
j:function(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gI:function(a){return a&0x1FFFFFFF},
v:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a+b},
U:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a-b},
ai:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a/b},
G:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a*b},
c4:function(a,b){if((a|0)===a)if(b>=1||!1)return a/b|0
return this.e1(a,b)},
bE:function(a,b){return(a|0)===a?a/b|0:this.e1(a,b)},
e1:function(a,b){var z=a/b
if(z>=-2147483648&&z<=2147483647)return z|0
if(z>0){if(z!==1/0)return Math.floor(z)}else if(z>-1/0)return Math.ceil(z)
throw H.c(new P.u("Result of truncating division is "+H.b(z)+": "+H.b(a)+" ~/ "+b))},
f9:function(a,b){if(b<0)throw H.c(H.L(b))
return b>31?0:a<<b>>>0},
fa:function(a,b){var z
if(b<0)throw H.c(H.L(b))
if(a>0)z=b>31?0:a>>>b
else{z=b>31?31:b
z=a>>z>>>0}return z},
cz:function(a,b){var z
if(a>0)z=b>31?0:a>>>b
else{z=b>31?31:b
z=a>>z>>>0}return z},
fs:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return(a^b)>>>0},
aj:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a<b},
bX:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a>b},
bV:function(a,b){if(typeof b!=="number")throw H.c(H.L(b))
return a>=b},
$isbh:1},
dS:{"^":"bu;",$isbh:1,$isy:1},
dR:{"^":"bu;",$isbh:1},
bv:{"^":"k;",
cH:function(a,b){if(b<0)throw H.c(H.M(a,b))
if(b>=a.length)H.B(H.M(a,b))
return a.charCodeAt(b)},
aR:function(a,b){if(b>=a.length)throw H.c(H.M(a,b))
return a.charCodeAt(b)},
ez:function(a,b,c){var z,y
if(c>b.length)throw H.c(P.G(c,0,b.length,null,null))
z=a.length
if(c+z>b.length)return
for(y=0;y<z;++y)if(this.aR(b,c+y)!==this.aR(a,y))return
return new H.js(c,b,a)},
v:function(a,b){if(typeof b!=="string")throw H.c(P.cn(b,null,null))
return a+b},
i7:function(a,b){var z,y
z=b.length
y=a.length
if(z>y)return!1
return b===this.dd(a,y-z)},
iK:function(a,b,c){H.d5(c)
return H.dc(a,b,c)},
fc:function(a,b,c){var z
if(c>a.length)throw H.c(P.G(c,0,a.length,null,null))
if(typeof b==="string"){z=c+b.length
if(z>a.length)return!1
return b===a.substring(c,z)}return J.fF(b,a,c)!=null},
fb:function(a,b){return this.fc(a,b,0)},
al:function(a,b,c){var z
if(typeof b!=="number"||Math.floor(b)!==b)H.B(H.L(b))
if(c==null)c=a.length
if(typeof c!=="number"||Math.floor(c)!==c)H.B(H.L(c))
z=J.a5(b)
if(z.aj(b,0))throw H.c(P.b9(b,null,null))
if(z.bX(b,c))throw H.c(P.b9(b,null,null))
if(J.az(c,a.length))throw H.c(P.b9(c,null,null))
return a.substring(b,c)},
dd:function(a,b){return this.al(a,b,null)},
iP:function(a){return a.toLowerCase()},
eR:function(a){var z,y,x,w,v
z=a.trim()
y=z.length
if(y===0)return z
if(this.aR(z,0)===133){x=J.il(z,1)
if(x===y)return""}else x=0
w=y-1
v=this.cH(z,w)===133?J.im(z,w):y
if(x===0&&v===y)return z
return z.substring(x,v)},
G:function(a,b){var z,y
if(typeof b!=="number")return H.l(b)
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw H.c(C.v)
for(z=a,y="";!0;){if((b&1)===1)y=z+y
b=b>>>1
if(b===0)break
z+=z}return y},
hR:function(a,b,c){if(c>a.length)throw H.c(P.G(c,0,a.length,null,null))
return H.m4(a,b,c)},
gT:function(a){return a.length!==0},
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
$isS:1,
$asS:I.Q,
$isq:1,
w:{
dT:function(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
il:function(a,b){var z,y
for(z=a.length;b<z;){y=C.e.aR(a,b)
if(y!==32&&y!==13&&!J.dT(y))break;++b}return b},
im:function(a,b){var z,y
for(;b>0;b=z){z=b-1
y=C.e.cH(a,z)
if(y!==32&&y!==13&&!J.dT(y))break}return b}}}}],["","",,H,{"^":"",
eY:function(a){if(a<0)H.B(P.G(a,0,null,"count",null))
return a},
cD:function(){return new P.a4("No element")},
ig:function(){return new P.a4("Too many elements")},
dQ:function(){return new P.a4("Too few elements")},
i:{"^":"R;$ti",$asi:null},
b5:{"^":"i;$ti",
gH:function(a){return new H.bT(this,this.gi(this),0,null)},
gD:function(a){return this.gi(this)===0},
d7:function(a,b){return this.fi(0,b)},
af:function(a,b){return new H.b6(this,b,[H.H(this,"b5",0),null])},
aB:function(a,b){var z,y,x
z=H.p([],[H.H(this,"b5",0)])
C.a.si(z,this.gi(this))
for(y=0;y<this.gi(this);++y){x=this.L(0,y)
if(y>=z.length)return H.a(z,y)
z[y]=x}return z},
aL:function(a){return this.aB(a,!0)}},
cP:{"^":"b5;a,b,c,$ti",
gfW:function(){var z,y
z=J.a0(this.a)
y=this.c
if(y==null||y>z)return z
return y},
ghz:function(){var z,y
z=J.a0(this.a)
y=this.b
if(y>z)return z
return y},
gi:function(a){var z,y,x
z=J.a0(this.a)
y=this.b
if(y>=z)return 0
x=this.c
if(x==null||x>=z)return z-y
if(typeof x!=="number")return x.U()
return x-y},
L:function(a,b){var z,y
z=this.ghz()
if(typeof b!=="number")return H.l(b)
y=z+b
if(!(b<0)){z=this.gfW()
if(typeof z!=="number")return H.l(z)
z=y>=z}else z=!0
if(z)throw H.c(P.ai(b,this,"index",null,null))
return J.b_(this.a,y)},
iO:function(a,b){var z,y,x
if(b<0)H.B(P.G(b,0,null,"count",null))
z=this.c
y=this.b
x=y+b
if(z==null)return H.eo(this.a,y,x,H.F(this,0))
else{if(z<x)return this
return H.eo(this.a,y,x,H.F(this,0))}},
aB:function(a,b){var z,y,x,w,v,u,t,s,r
z=this.b
y=this.a
x=J.w(y)
w=x.gi(y)
v=this.c
if(v!=null&&v<w)w=v
if(typeof w!=="number")return w.U()
u=w-z
if(u<0)u=0
t=H.p(new Array(u),this.$ti)
for(s=0;s<u;++s){r=x.L(y,z+s)
if(s>=t.length)return H.a(t,s)
t[s]=r
if(x.gi(y)<w)throw H.c(new P.a7(this))}return t},
fB:function(a,b,c,d){var z,y
z=this.b
if(z<0)H.B(P.G(z,0,null,"start",null))
y=this.c
if(y!=null){if(y<0)H.B(P.G(y,0,null,"end",null))
if(z>y)throw H.c(P.G(z,0,y,"start",null))}},
w:{
eo:function(a,b,c,d){var z=new H.cP(a,b,c,[d])
z.fB(a,b,c,d)
return z}}},
bT:{"^":"e;a,b,c,d",
gt:function(){return this.d},
n:function(){var z,y,x,w
z=this.a
y=J.w(z)
x=y.gi(z)
if(this.b!==x)throw H.c(new P.a7(z))
w=this.c
if(w>=x){this.d=null
return!1}this.d=y.L(z,w);++this.c
return!0}},
bU:{"^":"R;a,b,$ti",
gH:function(a){return new H.iF(null,J.E(this.a),this.b,this.$ti)},
gi:function(a){return J.a0(this.a)},
gD:function(a){return J.fz(this.a)},
L:function(a,b){return this.b.$1(J.b_(this.a,b))},
$asR:function(a,b){return[b]},
w:{
bV:function(a,b,c,d){if(!!J.j(a).$isi)return new H.cw(a,b,[c,d])
return new H.bU(a,b,[c,d])}}},
cw:{"^":"bU;a,b,$ti",$isi:1,
$asi:function(a,b){return[b]}},
iF:{"^":"bR;a,b,c,$ti",
n:function(){var z=this.b
if(z.n()){this.a=this.c.$1(z.gt())
return!0}this.a=null
return!1},
gt:function(){return this.a}},
b6:{"^":"b5;a,b,$ti",
gi:function(a){return J.a0(this.a)},
L:function(a,b){return this.b.$1(J.b_(this.a,b))},
$asb5:function(a,b){return[b]},
$asi:function(a,b){return[b]},
$asR:function(a,b){return[b]}},
cT:{"^":"R;a,b,$ti",
gH:function(a){return new H.jL(J.E(this.a),this.b,this.$ti)},
af:function(a,b){return new H.bU(this,b,[H.F(this,0),null])}},
jL:{"^":"bR;a,b,$ti",
n:function(){var z,y
for(z=this.a,y=this.b;z.n();)if(y.$1(z.gt())===!0)return!0
return!1},
gt:function(){return this.a.gt()}},
ep:{"^":"R;a,b,$ti",
gH:function(a){return new H.jv(J.E(this.a),this.b,this.$ti)},
w:{
ju:function(a,b,c){if(b<0)throw H.c(P.aA(b))
if(!!J.j(a).$isi)return new H.hq(a,b,[c])
return new H.ep(a,b,[c])}}},
hq:{"^":"ep;a,b,$ti",
gi:function(a){var z,y
z=J.a0(this.a)
y=this.b
if(z>y)return y
return z},
$isi:1,
$asi:null},
jv:{"^":"bR;a,b,$ti",
n:function(){if(--this.b>=0)return this.a.n()
this.b=-1
return!1},
gt:function(){if(this.b<0)return
return this.a.gt()}},
ej:{"^":"R;a,b,$ti",
gH:function(a){return new H.jm(J.E(this.a),this.b,this.$ti)},
w:{
jl:function(a,b,c){if(!!J.j(a).$isi)return new H.hp(a,H.eY(b),[c])
return new H.ej(a,H.eY(b),[c])}}},
hp:{"^":"ej;a,b,$ti",
gi:function(a){var z=J.a0(this.a)-this.b
if(z>=0)return z
return 0},
$isi:1,
$asi:null},
jm:{"^":"bR;a,b,$ti",
n:function(){var z,y
for(z=this.a,y=0;y<this.b;++y)z.n()
this.b=0
return z.n()},
gt:function(){return this.a.gt()}},
dM:{"^":"e;$ti",
si:function(a,b){throw H.c(new P.u("Cannot change the length of a fixed-length list"))},
C:function(a,b){throw H.c(new P.u("Cannot add to a fixed-length list"))},
A:function(a,b){throw H.c(new P.u("Cannot remove from a fixed-length list"))},
ag:function(a,b){throw H.c(new P.u("Cannot remove from a fixed-length list"))}},
cQ:{"^":"e;ha:a<",
F:function(a,b){if(b==null)return!1
return b instanceof H.cQ&&J.J(this.a,b.a)},
gI:function(a){var z,y
z=this._hashCode
if(z!=null)return z
y=J.a_(this.a)
if(typeof y!=="number")return H.l(y)
z=536870911&664597*y
this._hashCode=z
return z},
j:function(a){return'Symbol("'+H.b(this.a)+'")'}}}],["","",,H,{"^":"",
bE:function(a,b){var z=a.b6(b)
if(!init.globalState.d.cy)init.globalState.f.bh()
return z},
fp:function(a,b){var z,y,x,w,v,u
z={}
z.a=b
if(b==null){b=[]
z.a=b
y=b}else y=b
if(!J.j(y).$ish)throw H.c(P.aA("Arguments to main must be a List: "+H.b(y)))
init.globalState=new H.kC(0,0,1,null,null,null,null,null,null,null,null,null,a)
y=init.globalState
x=self.window==null
w=self.Worker
v=x&&!!self.postMessage
y.x=v
v=!v
if(v)w=w!=null&&$.$get$dO()!=null
else w=!0
y.y=w
y.r=x&&v
y.f=new H.k8(P.cJ(null,H.bC),0)
x=P.y
y.z=new H.a1(0,null,null,null,null,null,0,[x,H.cZ])
y.ch=new H.a1(0,null,null,null,null,null,0,[x,null])
if(y.x===!0){w=new H.kB()
y.Q=w
self.onmessage=function(c,d){return function(e){c(d,e)}}(H.i8,w)
self.dartPrint=self.dartPrint||function(c){return function(d){if(self.console&&self.console.log)self.console.log(d)
else self.postMessage(c(d))}}(H.kD)}if(init.globalState.x===!0)return
y=init.globalState.a++
w=P.a2(null,null,null,x)
v=new H.c0(0,null,!1)
u=new H.cZ(y,new H.a1(0,null,null,null,null,null,0,[x,H.c0]),w,init.createNewIsolate(),v,new H.aL(H.cg()),new H.aL(H.cg()),!1,!1,[],P.a2(null,null,null,null),null,null,!1,!0,P.a2(null,null,null,null))
w.C(0,0)
u.dm(0,v)
init.globalState.e=u
init.globalState.d=u
if(H.aI(a,{func:1,args:[,]}))u.b6(new H.m2(z,a))
else if(H.aI(a,{func:1,args:[,,]}))u.b6(new H.m3(z,a))
else u.b6(a)
init.globalState.f.bh()},
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
z=new H.c3(!0,[]).at(b.data)
y=J.w(z)
switch(y.h(z,"command")){case"start":init.globalState.b=y.h(z,"id")
x=y.h(z,"functionName")
w=x==null?init.globalState.cx:init.globalFunctions[x]()
v=y.h(z,"args")
u=new H.c3(!0,[]).at(y.h(z,"msg"))
t=y.h(z,"isSpawnUri")
s=y.h(z,"startPaused")
r=new H.c3(!0,[]).at(y.h(z,"replyTo"))
y=init.globalState.a++
q=P.y
p=P.a2(null,null,null,q)
o=new H.c0(0,null,!1)
n=new H.cZ(y,new H.a1(0,null,null,null,null,null,0,[q,H.c0]),p,init.createNewIsolate(),o,new H.aL(H.cg()),new H.aL(H.cg()),!1,!1,[],P.a2(null,null,null,null),null,null,!1,!0,P.a2(null,null,null,null))
p.C(0,0)
n.dm(0,o)
init.globalState.f.a.a9(new H.bC(n,new H.i9(w,v,u,t,s,r),"worker-start"))
init.globalState.d=n
init.globalState.f.bh()
break
case"spawn-worker":break
case"message":if(y.h(z,"port")!=null)J.b0(y.h(z,"port"),y.h(z,"msg"))
init.globalState.f.bh()
break
case"close":init.globalState.ch.A(0,$.$get$dP().h(0,a))
a.terminate()
init.globalState.f.bh()
break
case"log":H.i7(y.h(z,"msg"))
break
case"print":if(init.globalState.x===!0){y=init.globalState.Q
q=P.au(["command","print","msg",z])
q=new H.aR(!0,P.bb(null,P.y)).a4(q)
y.toString
self.postMessage(q)}else P.cf(y.h(z,"msg"))
break
case"error":throw H.c(y.h(z,"msg"))}},null,null,4,0,null,19,0],
i7:function(a){var z,y,x,w
if(init.globalState.x===!0){y=init.globalState.Q
x=P.au(["command","log","msg",a])
x=new H.aR(!0,P.bb(null,P.y)).a4(x)
y.toString
self.postMessage(x)}else try{self.console.log(a)}catch(w){H.D(w)
z=H.Z(w)
y=P.bO(z)
throw H.c(y)}},
ia:function(a,b,c,d,e,f){var z,y,x,w
z=init.globalState.d
y=z.a
$.eb=$.eb+("_"+y)
$.ec=$.ec+("_"+y)
y=z.e
x=init.globalState.d.a
w=z.f
J.b0(f,["spawned",new H.c5(y,x),w,z.r])
x=new H.ib(a,b,c,d,z)
if(e===!0){z.e9(w,w)
init.globalState.f.a.a9(new H.bC(z,x,"start isolate"))}else x.$0()},
lb:function(a){return new H.c3(!0,[]).at(new H.aR(!1,P.bb(null,P.y)).a4(a))},
m2:{"^":"f:2;a,b",
$0:function(){this.b.$1(this.a.a)}},
m3:{"^":"f:2;a,b",
$0:function(){this.b.$2(this.a.a,null)}},
kC:{"^":"e;a,b,c,d,e,f,r,x,y,z,Q,ch,cx",w:{
kD:[function(a){var z=P.au(["command","print","msg",a])
return new H.aR(!0,P.bb(null,P.y)).a4(z)},null,null,2,0,null,9]}},
cZ:{"^":"e;a,b,c,iw:d<,hS:e<,f,r,io:x?,bb:y<,hY:z<,Q,ch,cx,cy,db,dx",
e9:function(a,b){if(!this.f.F(0,a))return
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
if(w===y.c)y.dL();++y.d}this.y=!1}this.cA()},
hE:function(a,b){var z,y,x
if(this.ch==null)this.ch=[]
for(z=J.j(a),y=0;x=this.ch,y<x.length;y+=2)if(z.F(a,x[y])){z=this.ch
x=y+1
if(x>=z.length)return H.a(z,x)
z[x]=b
return}x.push(a)
this.ch.push(b)},
iH:function(a){var z,y,x
if(this.ch==null)return
for(z=J.j(a),y=0;x=this.ch,y<x.length;y+=2)if(z.F(a,x[y])){z=this.ch
x=y+2
z.toString
if(typeof z!=="object"||z===null||!!z.fixed$length)H.B(new P.u("removeRange"))
P.cO(y,x,z.length,null,null,null)
z.splice(y,x-y)
return}},
f8:function(a,b){if(!this.r.F(0,a))return
this.db=b},
ih:function(a,b,c){var z=J.j(b)
if(!z.F(b,0))z=z.F(b,1)&&!this.cy
else z=!0
if(z){J.b0(a,c)
return}z=this.cx
if(z==null){z=P.cJ(null,null)
this.cx=z}z.a9(new H.kr(a,c))},
ig:function(a,b){var z
if(!this.r.F(0,a))return
z=J.j(b)
if(!z.F(b,0))z=z.F(b,1)&&!this.cy
else z=!0
if(z){this.cL()
return}z=this.cx
if(z==null){z=P.cJ(null,null)
this.cx=z}z.a9(this.gix())},
ii:function(a,b){var z,y,x
z=this.dx
if(z.a===0){if(this.db===!0&&this===init.globalState.e)return
if(self.console&&self.console.error)self.console.error(a,b)
else{P.cf(a)
if(b!=null)P.cf(b)}return}y=new Array(2)
y.fixed$length=Array
y[0]=J.C(a)
y[1]=b==null?null:J.C(b)
for(x=new P.bD(z,z.r,null,null),x.c=z.e;x.n();)J.b0(x.d,y)},
b6:function(a){var z,y,x,w,v,u,t
z=init.globalState.d
init.globalState.d=this
$=this.d
y=null
x=this.cy
this.cy=!0
try{y=a.$0()}catch(u){w=H.D(u)
v=H.Z(u)
this.ii(w,v)
if(this.db===!0){this.cL()
if(this===init.globalState.e)throw u}}finally{this.cy=x
init.globalState.d=z
if(z!=null)$=z.giw()
if(this.cx!=null)for(;t=this.cx,!t.gD(t);)this.cx.eK().$0()}return y},
ic:function(a){var z=J.w(a)
switch(z.h(a,0)){case"pause":this.e9(z.h(a,1),z.h(a,2))
break
case"resume":this.iI(z.h(a,1))
break
case"add-ondone":this.hE(z.h(a,1),z.h(a,2))
break
case"remove-ondone":this.iH(z.h(a,1))
break
case"set-errors-fatal":this.f8(z.h(a,1),z.h(a,2))
break
case"ping":this.ih(z.h(a,1),z.h(a,2),z.h(a,3))
break
case"kill":this.ig(z.h(a,1),z.h(a,2))
break
case"getErrors":this.dx.C(0,z.h(a,1))
break
case"stopErrors":this.dx.A(0,z.h(a,1))
break}},
cN:function(a){return this.b.h(0,a)},
dm:function(a,b){var z=this.b
if(z.M(a))throw H.c(P.bO("Registry: ports must be registered only once."))
z.l(0,a,b)},
cA:function(){var z=this.b
if(z.gi(z)-this.c.a>0||this.y||!this.x)init.globalState.z.l(0,this.a,this)
else this.cL()},
cL:[function(){var z,y,x,w,v
z=this.cx
if(z!=null)z.a7(0)
for(z=this.b,y=z.gd6(z),y=y.gH(y);y.n();)y.gt().fP()
z.a7(0)
this.c.a7(0)
init.globalState.z.A(0,this.a)
this.dx.a7(0)
if(this.ch!=null){for(x=0;z=this.ch,y=z.length,x<y;x+=2){w=z[x]
v=x+1
if(v>=y)return H.a(z,v)
J.b0(w,z[v])}this.ch=null}},"$0","gix",0,0,1]},
kr:{"^":"f:1;a,b",
$0:[function(){J.b0(this.a,this.b)},null,null,0,0,null,"call"]},
k8:{"^":"e;a,b",
hZ:function(){var z=this.a
if(z.b===z.c)return
return z.eK()},
eM:function(){var z,y,x
z=this.hZ()
if(z==null){if(init.globalState.e!=null)if(init.globalState.z.M(init.globalState.e.a))if(init.globalState.r===!0){y=init.globalState.e.b
y=y.gD(y)}else y=!1
else y=!1
else y=!1
if(y)H.B(P.bO("Program exited with open ReceivePorts."))
y=init.globalState
if(y.x===!0){x=y.z
x=x.gD(x)&&y.f.b===0}else x=!1
if(x){y=y.Q
x=P.au(["command","close"])
x=new H.aR(!0,new P.eT(0,null,null,null,null,null,0,[null,P.y])).a4(x)
y.toString
self.postMessage(x)}return!1}z.iF()
return!0},
dY:function(){if(self.window!=null)new H.k9(this).$0()
else for(;this.eM(););},
bh:function(){var z,y,x,w,v
if(init.globalState.x!==!0)this.dY()
else try{this.dY()}catch(x){z=H.D(x)
y=H.Z(x)
w=init.globalState.Q
v=P.au(["command","error","msg",H.b(z)+"\n"+H.b(y)])
v=new H.aR(!0,P.bb(null,P.y)).a4(v)
w.toString
self.postMessage(v)}}},
k9:{"^":"f:1;a",
$0:function(){if(!this.a.eM())return
P.jA(C.o,this)}},
bC:{"^":"e;a,b,c",
iF:function(){var z=this.a
if(z.gbb()){z.ghY().push(this)
return}z.b6(this.b)}},
kB:{"^":"e;"},
i9:{"^":"f:2;a,b,c,d,e,f",
$0:function(){H.ia(this.a,this.b,this.c,this.d,this.e,this.f)}},
ib:{"^":"f:1;a,b,c,d,e",
$0:function(){var z,y
z=this.e
z.sio(!0)
if(this.d!==!0)this.a.$1(this.c)
else{y=this.a
if(H.aI(y,{func:1,args:[,,]}))y.$2(this.b,this.c)
else if(H.aI(y,{func:1,args:[,]}))y.$1(this.b)
else y.$0()}z.cA()}},
eI:{"^":"e;"},
c5:{"^":"eI;b,a",
bZ:function(a,b){var z,y,x
z=init.globalState.z.h(0,this.a)
if(z==null)return
y=this.b
if(y.gdQ())return
x=H.lb(b)
if(z.ghS()===y){z.ic(x)
return}init.globalState.f.a.a9(new H.bC(z,new H.kL(this,x),"receive"))},
F:function(a,b){if(b==null)return!1
return b instanceof H.c5&&J.J(this.b,b.b)},
gI:function(a){return this.b.gcm()}},
kL:{"^":"f:2;a,b",
$0:function(){var z=this.a.b
if(!z.gdQ())z.fI(this.b)}},
d_:{"^":"eI;b,c,a",
bZ:function(a,b){var z,y,x
z=P.au(["command","message","port",this,"msg",b])
y=new H.aR(!0,P.bb(null,P.y)).a4(z)
if(init.globalState.x===!0){init.globalState.Q.toString
self.postMessage(y)}else{x=init.globalState.ch.h(0,this.b)
if(x!=null)x.postMessage(y)}},
F:function(a,b){if(b==null)return!1
return b instanceof H.d_&&J.J(this.b,b.b)&&J.J(this.a,b.a)&&J.J(this.c,b.c)},
gI:function(a){var z,y,x
z=J.dg(this.b,16)
y=J.dg(this.a,8)
x=this.c
if(typeof x!=="number")return H.l(x)
return(z^y^x)>>>0}},
c0:{"^":"e;cm:a<,b,dQ:c<",
fP:function(){this.c=!0
this.b=null},
fI:function(a){if(this.c)return
this.b.$1(a)},
$isjb:1},
jw:{"^":"e;a,b,c",
aI:function(){if(self.setTimeout!=null){if(this.b)throw H.c(new P.u("Timer in event loop cannot be canceled."))
var z=this.c
if(z==null)return;--init.globalState.f.b
self.clearTimeout(z)
this.c=null}else throw H.c(new P.u("Canceling a timer."))},
fC:function(a,b){var z,y
if(a===0)z=self.setTimeout==null||init.globalState.x===!0
else z=!1
if(z){this.c=1
z=init.globalState.f
y=init.globalState.d
z.a.a9(new H.bC(y,new H.jy(this,b),"timer"))
this.b=!0}else if(self.setTimeout!=null){++init.globalState.f.b
this.c=self.setTimeout(H.aW(new H.jz(this,b),0),a)}else throw H.c(new P.u("Timer greater than 0."))},
w:{
jx:function(a,b){var z=new H.jw(!0,!1,null)
z.fC(a,b)
return z}}},
jy:{"^":"f:1;a,b",
$0:function(){this.a.c=null
this.b.$0()}},
jz:{"^":"f:1;a,b",
$0:[function(){this.a.c=null;--init.globalState.f.b
this.b.$0()},null,null,0,0,null,"call"]},
aL:{"^":"e;cm:a<",
gI:function(a){var z,y,x
z=this.a
y=J.a5(z)
x=y.fa(z,0)
y=y.c4(z,4294967296)
if(typeof y!=="number")return H.l(y)
z=x^y
z=(~z>>>0)+(z<<15>>>0)&4294967295
z=((z^z>>>12)>>>0)*5&4294967295
z=((z^z>>>4)>>>0)*2057&4294967295
return(z^z>>>16)>>>0},
F:function(a,b){var z,y
if(b==null)return!1
if(b===this)return!0
if(b instanceof H.aL){z=this.a
y=b.a
return z==null?y==null:z===y}return!1}},
aR:{"^":"e;a,b",
a4:[function(a){var z,y,x,w,v
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
z=this.b
y=z.h(0,a)
if(y!=null)return["ref",y]
z.l(0,a,z.gi(z))
z=J.j(a)
if(!!z.$isdW)return["buffer",a]
if(!!z.$isbY)return["typed",a]
if(!!z.$isS)return this.f3(a)
if(!!z.$isi6){x=this.gf0()
w=a.gab()
w=H.bV(w,x,H.H(w,"R",0),null)
w=P.av(w,!0,H.H(w,"R",0))
z=z.gd6(a)
z=H.bV(z,x,H.H(z,"R",0),null)
return["map",w,P.av(z,!0,H.H(z,"R",0))]}if(!!z.$isik)return this.f4(a)
if(!!z.$isk)this.eS(a)
if(!!z.$isjb)this.bn(a,"RawReceivePorts can't be transmitted:")
if(!!z.$isc5)return this.f5(a)
if(!!z.$isd_)return this.f6(a)
if(!!z.$isf){v=a.$static_name
if(v==null)this.bn(a,"Closures can't be transmitted:")
return["function",v]}if(!!z.$isaL)return["capability",a.a]
if(!(a instanceof P.e))this.eS(a)
return["dart",init.classIdExtractor(a),this.f2(init.classFieldsExtractor(a))]},"$1","gf0",2,0,0,10],
bn:function(a,b){throw H.c(new P.u((b==null?"Can't transmit:":b)+" "+H.b(a)))},
eS:function(a){return this.bn(a,null)},
f3:function(a){var z=this.f1(a)
if(!!a.fixed$length)return["fixed",z]
if(!a.fixed$length)return["extendable",z]
if(!a.immutable$list)return["mutable",z]
if(a.constructor===Array)return["const",z]
this.bn(a,"Can't serialize indexable: ")},
f1:function(a){var z,y,x
z=[]
C.a.si(z,a.length)
for(y=0;y<a.length;++y){x=this.a4(a[y])
if(y>=z.length)return H.a(z,y)
z[y]=x}return z},
f2:function(a){var z
for(z=0;z<a.length;++z)C.a.l(a,z,this.a4(a[z]))
return a},
f4:function(a){var z,y,x,w
if(!!a.constructor&&a.constructor!==Object)this.bn(a,"Only plain JS Objects are supported:")
z=Object.keys(a)
y=[]
C.a.si(y,z.length)
for(x=0;x<z.length;++x){w=this.a4(a[z[x]])
if(x>=y.length)return H.a(y,x)
y[x]=w}return["js-object",z,y]},
f6:function(a){if(this.a)return["sendport",a.b,a.a,a.c]
return["raw sendport",a]},
f5:function(a){if(this.a)return["sendport",init.globalState.b,a.a,a.b.gcm()]
return["raw sendport",a]}},
c3:{"^":"e;a,b",
at:[function(a){var z,y,x,w,v,u
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
if(typeof a!=="object"||a===null||a.constructor!==Array)throw H.c(P.aA("Bad serialized message: "+H.b(a)))
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
y=H.p(this.b5(x),[null])
y.fixed$length=Array
return y
case"extendable":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return H.p(this.b5(x),[null])
case"mutable":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return this.b5(x)
case"const":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
y=H.p(this.b5(x),[null])
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
return new H.aL(a[1])
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
z=J.w(a)
y=0
while(!0){x=z.gi(a)
if(typeof x!=="number")return H.l(x)
if(!(y<x))break
z.l(a,y,this.at(z.h(a,y)));++y}return a},
i1:function(a){var z,y,x,w,v,u
z=a.length
if(1>=z)return H.a(a,1)
y=a[1]
if(2>=z)return H.a(a,2)
x=a[2]
w=P.bS()
this.b.push(w)
y=J.dn(y,this.gi_()).aL(0)
for(z=J.w(y),v=J.w(x),u=0;u<z.gi(y);++u)w.l(0,z.h(y,u),this.at(v.h(x,u)))
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
u=v.cN(w)
if(u==null)return
t=new H.c5(u,x)}else t=new H.d_(y,w,x)
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
z=J.w(y)
v=J.w(x)
u=0
while(!0){t=z.gi(y)
if(typeof t!=="number")return H.l(t)
if(!(u<t))break
w[z.h(y,u)]=this.at(v.h(x,u));++u}return w}}}],["","",,H,{"^":"",
dz:function(){throw H.c(new P.u("Cannot modify unmodifiable Map"))},
lD:function(a){return init.types[a]},
fi:function(a,b){var z
if(b!=null){z=b.x
if(z!=null)return z}return!!J.j(a).$isY},
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
e9:function(a,b){if(b==null)throw H.c(new P.bP(a,null,null))
return b.$1(a)},
ed:function(a,b,c){var z,y
z=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(z==null)return H.e9(a,c)
if(3>=z.length)return H.a(z,3)
y=z[3]
if(y!=null)return parseInt(a,10)
if(z[2]!=null)return parseInt(a,16)
return H.e9(a,c)},
e8:function(a,b){return b.$1(a)},
j5:function(a,b){var z,y
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return H.e8(a,b)
z=parseFloat(a)
if(isNaN(z)){y=C.e.eR(a)
if(y==="NaN"||y==="+NaN"||y==="-NaN")return z
return H.e8(a,b)}return z},
c_:function(a){var z,y,x,w,v,u,t,s
z=J.j(a)
y=z.constructor
if(typeof y=="function"){x=y.name
w=typeof x==="string"?x:null}else w=null
if(w==null||z===C.x||!!J.j(a).$isbA){v=C.q(a)
if(v==="Object"){u=a.constructor
if(typeof u=="function"){t=String(u).match(/^\s*function\s*([\w$]*)\s*\(/)
s=t==null?null:t[1]
if(typeof s==="string"&&/^\w+$/.test(s))w=s}if(w==null)w=v}else w=v}w=w
if(w.length>1&&C.e.aR(w,0)===36)w=C.e.dd(w,1)
return function(b,c){return b.replace(/[^<,> ]+/g,function(d){return c[d]||d})}(w+H.fj(H.cb(a),0,null),init.mangledGlobalNames)},
bZ:function(a){return"Instance of '"+H.c_(a)+"'"},
a3:function(a){var z
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){z=a-65536
return String.fromCharCode((55296|C.f.cz(z,10))>>>0,56320|z&1023)}throw H.c(P.G(a,0,1114111,null,null))},
X:function(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
j4:function(a){return a.b?H.X(a).getUTCFullYear()+0:H.X(a).getFullYear()+0},
j2:function(a){return a.b?H.X(a).getUTCMonth()+1:H.X(a).getMonth()+1},
iZ:function(a){return a.b?H.X(a).getUTCDate()+0:H.X(a).getDate()+0},
j_:function(a){return a.b?H.X(a).getUTCHours()+0:H.X(a).getHours()+0},
j1:function(a){return a.b?H.X(a).getUTCMinutes()+0:H.X(a).getMinutes()+0},
j3:function(a){return a.b?H.X(a).getUTCSeconds()+0:H.X(a).getSeconds()+0},
j0:function(a){return a.b?H.X(a).getUTCMilliseconds()+0:H.X(a).getMilliseconds()+0},
cN:function(a,b){if(a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string")throw H.c(H.L(a))
return a[b]},
ee:function(a,b,c){if(a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string")throw H.c(H.L(a))
a[b]=c},
ea:function(a,b,c){var z,y,x
z={}
z.a=0
y=[]
x=[]
z.a=b.length
C.a.V(y,b)
z.b=""
if(c!=null&&!c.gD(c))c.J(0,new H.iY(z,y,x))
return J.fG(a,new H.ii(C.L,""+"$"+z.a+z.b,0,y,x,null))},
iX:function(a,b){var z,y
z=b instanceof Array?b:P.av(b,!0,null)
y=z.length
if(y===0){if(!!a.$0)return a.$0()}else if(y===1){if(!!a.$1)return a.$1(z[0])}else if(y===2){if(!!a.$2)return a.$2(z[0],z[1])}else if(y===3){if(!!a.$3)return a.$3(z[0],z[1],z[2])}else if(y===4){if(!!a.$4)return a.$4(z[0],z[1],z[2],z[3])}else if(y===5)if(!!a.$5)return a.$5(z[0],z[1],z[2],z[3],z[4])
return H.iW(a,z)},
iW:function(a,b){var z,y,x,w,v,u
z=b.length
y=a[""+"$"+z]
if(y==null){y=J.j(a)["call*"]
if(y==null)return H.ea(a,b,null)
x=H.eg(y)
w=x.d
v=w+x.e
if(x.f||w>z||v<z)return H.ea(a,b,null)
b=P.av(b,!0,null)
for(u=z;u<v;++u)C.a.C(b,init.metadata[x.hX(0,u)])}return y.apply(a,b)},
l:function(a){throw H.c(H.L(a))},
a:function(a,b){if(a==null)J.a0(a)
throw H.c(H.M(a,b))},
M:function(a,b){var z,y
if(typeof b!=="number"||Math.floor(b)!==b)return new P.as(!0,b,"index",null)
z=J.a0(a)
if(!(b<0)){if(typeof z!=="number")return H.l(z)
y=b>=z}else y=!0
if(y)return P.ai(b,a,"index",null,z)
return P.b9(b,"index",null)},
L:function(a){return new P.as(!0,a,null,null)},
bG:function(a){if(typeof a!=="number")throw H.c(H.L(a))
return a},
d5:function(a){if(typeof a!=="string")throw H.c(H.L(a))
return a},
c:function(a){var z
if(a==null)a=new P.e4()
z=new Error()
z.dartException=a
if("defineProperty" in Object){Object.defineProperty(z,"message",{get:H.fq})
z.name=""}else z.toString=H.fq
return z},
fq:[function(){return J.C(this.dartException)},null,null,0,0,null],
B:function(a){throw H.c(a)},
A:function(a){throw H.c(new P.a7(a))},
D:function(a){var z,y,x,w,v,u,t,s,r,q,p,o,n,m,l
z=new H.m6(a)
if(a==null)return
if(typeof a!=="object")return a
if("dartException" in a)return z.$1(a.dartException)
else if(!("message" in a))return a
y=a.message
if("number" in a&&typeof a.number=="number"){x=a.number
w=x&65535
if((C.f.cz(x,16)&8191)===10)switch(w){case 438:return z.$1(H.cG(H.b(y)+" (Error "+w+")",null))
case 445:case 5007:v=H.b(y)+" (Error "+w+")"
return z.$1(new H.e3(v,null))}}if(a instanceof TypeError){u=$.$get$ev()
t=$.$get$ew()
s=$.$get$ex()
r=$.$get$ey()
q=$.$get$eC()
p=$.$get$eD()
o=$.$get$eA()
$.$get$ez()
n=$.$get$eF()
m=$.$get$eE()
l=u.a8(y)
if(l!=null)return z.$1(H.cG(y,l))
else{l=t.a8(y)
if(l!=null){l.method="call"
return z.$1(H.cG(y,l))}else{l=s.a8(y)
if(l==null){l=r.a8(y)
if(l==null){l=q.a8(y)
if(l==null){l=p.a8(y)
if(l==null){l=o.a8(y)
if(l==null){l=r.a8(y)
if(l==null){l=n.a8(y)
if(l==null){l=m.a8(y)
v=l!=null}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0
if(v)return z.$1(new H.e3(y,l==null?null:l.method))}}return z.$1(new H.jK(typeof y==="string"?y:""))}if(a instanceof RangeError){if(typeof y==="string"&&y.indexOf("call stack")!==-1)return new P.el()
y=function(b){try{return String(b)}catch(k){}return null}(a)
return z.$1(new P.as(!1,null,null,typeof y==="string"?y.replace(/^RangeError:\s*/,""):y))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof y==="string"&&y==="too much recursion")return new P.el()
return a},
Z:function(a){var z
if(a==null)return new H.eU(a,null)
z=a.$cachedTrace
if(z!=null)return z
return a.$cachedTrace=new H.eU(a,null)},
m_:function(a){if(a==null||typeof a!='object')return J.a_(a)
else return H.ax(a)},
lC:function(a,b){var z,y,x,w
z=a.length
for(y=0;y<z;y=w){x=y+1
w=x+1
b.l(0,a[y],a[x])}return b},
lM:[function(a,b,c,d,e,f,g){switch(c){case 0:return H.bE(b,new H.lN(a))
case 1:return H.bE(b,new H.lO(a,d))
case 2:return H.bE(b,new H.lP(a,d,e))
case 3:return H.bE(b,new H.lQ(a,d,e,f))
case 4:return H.bE(b,new H.lR(a,d,e,f,g))}throw H.c(P.bO("Unsupported number of arguments for wrapped closure"))},null,null,14,0,null,33,21,31,15,16,17,20],
aW:function(a,b){var z
if(a==null)return
z=a.$identity
if(!!z)return z
z=function(c,d,e,f){return function(g,h,i,j){return f(c,e,d,g,h,i,j)}}(a,b,init.globalState.d,H.lM)
a.$identity=z
return z},
h4:function(a,b,c,d,e,f){var z,y,x,w,v,u,t,s,r,q,p,o,n,m
z=b[0]
y=z.$callName
if(!!J.j(c).$ish){z.$reflectionInfo=c
x=H.eg(z).r}else x=c
w=d?Object.create(new H.jn().constructor.prototype):Object.create(new H.cs(null,null,null,null).constructor.prototype)
w.$initialize=w.constructor
if(d)v=function(){this.$initialize()}
else{u=$.ah
$.ah=J.d(u,1)
v=new Function("a,b,c,d"+u,"this.$initialize(a,b,c,d"+u+")")}w.constructor=v
v.prototype=w
if(!d){t=e.length==1&&!0
s=H.dx(a,z,t)
s.$reflectionInfo=c}else{w.$static_name=f
s=z
t=!1}if(typeof x=="number")r=function(g,h){return function(){return g(h)}}(H.lD,x)
else if(typeof x=="function")if(d)r=x
else{q=t?H.dv:H.ct
r=function(g,h){return function(){return g.apply({$receiver:h(this)},arguments)}}(x,q)}else throw H.c("Error in reflectionInfo.")
w.$S=r
w[y]=s
for(u=b.length,p=1;p<u;++p){o=b[p]
n=o.$callName
if(n!=null){m=d?o:H.dx(a,o,t)
w[n]=m}}w["call*"]=s
w.$R=z.$R
w.$D=z.$D
return v},
h1:function(a,b,c,d){var z=H.ct
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,z)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,z)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,z)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,z)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,z)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,z)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,z)}},
dx:function(a,b,c){var z,y,x,w,v,u,t
if(c)return H.h3(a,b)
z=b.$stubName
y=b.length
x=a[z]
w=b==null?x==null:b===x
v=!w||y>=27
if(v)return H.h1(y,!w,z,b)
if(y===0){w=$.ah
$.ah=J.d(w,1)
u="self"+H.b(w)
w="return function(){var "+u+" = this."
v=$.b1
if(v==null){v=H.bL("self")
$.b1=v}return new Function(w+H.b(v)+";return "+u+"."+H.b(z)+"();}")()}t="abcdefghijklmnopqrstuvwxyz".split("").splice(0,y).join(",")
w=$.ah
$.ah=J.d(w,1)
t+=H.b(w)
w="return function("+t+"){return this."
v=$.b1
if(v==null){v=H.bL("self")
$.b1=v}return new Function(w+H.b(v)+"."+H.b(z)+"("+t+");}")()},
h2:function(a,b,c,d){var z,y
z=H.ct
y=H.dv
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
h3:function(a,b){var z,y,x,w,v,u,t,s
z=H.h_()
y=$.du
if(y==null){y=H.bL("receiver")
$.du=y}x=b.$stubName
w=b.length
v=a[x]
u=b==null?v==null:b===v
t=!u||w>=28
if(t)return H.h2(w,!u,x,b)
if(w===1){y="return function(){return this."+H.b(z)+"."+H.b(x)+"(this."+H.b(y)+");"
u=$.ah
$.ah=J.d(u,1)
return new Function(y+H.b(u)+"}")()}s="abcdefghijklmnopqrstuvwxyz".split("").splice(0,w-1).join(",")
y="return function("+s+"){return this."+H.b(z)+"."+H.b(x)+"(this."+H.b(y)+", "+s+");"
u=$.ah
$.ah=J.d(u,1)
return new Function(y+H.b(u)+"}")()},
d6:function(a,b,c,d,e,f){var z
b.fixed$length=Array
if(!!J.j(c).$ish){c.fixed$length=Array
z=c}else z=c
return H.h4(a,b,z,!!d,e,f)},
lZ:function(a){if(typeof a==="number"||a==null)return a
throw H.c(H.dw(H.c_(a),"num"))},
m1:function(a,b){var z=J.w(b)
throw H.c(H.dw(H.c_(a),z.al(b,3,z.gi(b))))},
cc:function(a,b){var z
if(a!=null)z=(typeof a==="object"||typeof a==="function")&&J.j(a)[b]
else z=!0
if(z)return a
H.m1(a,b)},
lA:function(a){var z=J.j(a)
return"$S" in z?z.$S():null},
aI:function(a,b){var z
if(a==null)return!1
z=H.lA(a)
return z==null?!1:H.fh(z,b)},
m5:function(a){throw H.c(new P.hf(a))},
cg:function(){return(Math.random()*0x100000000>>>0)+(Math.random()*0x100000000>>>0)*4294967296},
d8:function(a){return init.getIsolateTag(a)},
p:function(a,b){a.$ti=b
return a},
cb:function(a){if(a==null)return
return a.$ti},
fg:function(a,b){return H.dd(a["$as"+H.b(b)],H.cb(a))},
H:function(a,b,c){var z=H.fg(a,b)
return z==null?null:z[c]},
F:function(a,b){var z=H.cb(a)
return z==null?null:z[b]},
aY:function(a,b){var z
if(a==null)return"dynamic"
if(typeof a==="object"&&a!==null&&a.constructor===Array)return a[0].builtin$cls+H.fj(a,1,b)
if(typeof a=="function")return a.builtin$cls
if(typeof a==="number"&&Math.floor(a)===a)return H.b(a)
if(typeof a.func!="undefined"){z=a.typedef
if(z!=null)return H.aY(z,b)
return H.le(a,b)}return"unknown-reified-type"},
le:function(a,b){var z,y,x,w,v,u,t,s,r,q,p
z=!!a.v?"void":H.aY(a.ret,b)
if("args" in a){y=a.args
for(x=y.length,w="",v="",u=0;u<x;++u,v=", "){t=y[u]
w=w+v+H.aY(t,b)}}else{w=""
v=""}if("opt" in a){s=a.opt
w+=v+"["
for(x=s.length,v="",u=0;u<x;++u,v=", "){t=s[u]
w=w+v+H.aY(t,b)}w+="]"}if("named" in a){r=a.named
w+=v+"{"
for(x=H.lB(r),q=x.length,v="",u=0;u<q;++u,v=", "){p=x[u]
w=w+v+H.aY(r[p],b)+(" "+H.b(p))}w+="}"}return"("+w+") => "+z},
fj:function(a,b,c){var z,y,x,w,v,u
if(a==null)return""
z=new P.aF("")
for(y=b,x=!0,w=!0,v="";y<a.length;++y){if(x)x=!1
else z.k=v+", "
u=a[y]
if(u!=null)w=!1
v=z.k+=H.aY(u,c)}return w?"":"<"+z.j(0)+">"},
dd:function(a,b){if(a==null)return b
a=a.apply(null,b)
if(a==null)return
if(typeof a==="object"&&a!==null&&a.constructor===Array)return a
if(typeof a=="function")return a.apply(null,b)
return b},
bH:function(a,b,c,d){var z,y
if(a==null)return!1
z=H.cb(a)
y=J.j(a)
if(y[b]==null)return!1
return H.fd(H.dd(y[d],z),c)},
fd:function(a,b){var z,y
if(a==null||b==null)return!0
z=a.length
for(y=0;y<z;++y)if(!H.a6(a[y],b[y]))return!1
return!0},
bf:function(a,b,c){return a.apply(b,H.fg(b,c))},
a6:function(a,b){var z,y,x,w,v,u
if(a===b)return!0
if(a==null||b==null)return!0
if(a.builtin$cls==="b7")return!0
if('func' in b)return H.fh(a,b)
if('func' in a)return b.builtin$cls==="cB"||b.builtin$cls==="e"
z=typeof a==="object"&&a!==null&&a.constructor===Array
y=z?a[0]:a
x=typeof b==="object"&&b!==null&&b.constructor===Array
w=x?b[0]:b
if(w!==y){v=H.aY(w,null)
if(!('$is'+v in y.prototype))return!1
u=y.prototype["$as"+v]}else u=null
if(!z&&u==null||!x)return!0
z=z?a.slice(1):null
x=b.slice(1)
return H.fd(H.dd(u,z),x)},
fc:function(a,b,c){var z,y,x,w,v
z=b==null
if(z&&a==null)return!0
if(z)return c
if(a==null)return!1
y=a.length
x=b.length
if(c){if(y<x)return!1}else if(y!==x)return!1
for(w=0;w<x;++w){z=a[w]
v=b[w]
if(!(H.a6(z,v)||H.a6(v,z)))return!1}return!0},
lp:function(a,b){var z,y,x,w,v,u
if(b==null)return!0
if(a==null)return!1
z=Object.getOwnPropertyNames(b)
z.fixed$length=Array
y=z
for(z=y.length,x=0;x<z;++x){w=y[x]
if(!Object.hasOwnProperty.call(a,w))return!1
v=b[w]
u=a[w]
if(!(H.a6(v,u)||H.a6(u,v)))return!1}return!0},
fh:function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o,n,m,l
if(!('func' in a))return!1
if("v" in a){if(!("v" in b)&&"ret" in b)return!1}else if(!("v" in b)){z=a.ret
y=b.ret
if(!(H.a6(z,y)||H.a6(y,z)))return!1}x=a.args
w=b.args
v=a.opt
u=b.opt
t=x!=null?x.length:0
s=w!=null?w.length:0
r=v!=null?v.length:0
q=u!=null?u.length:0
if(t>s)return!1
if(t+r<s+q)return!1
if(t===s){if(!H.fc(x,w,!1))return!1
if(!H.fc(v,u,!0))return!1}else{for(p=0;p<t;++p){o=x[p]
n=w[p]
if(!(H.a6(o,n)||H.a6(n,o)))return!1}for(m=p,l=0;m<s;++l,++m){o=v[l]
n=w[m]
if(!(H.a6(o,n)||H.a6(n,o)))return!1}for(m=0;m<q;++l,++m){o=v[l]
n=u[m]
if(!(H.a6(o,n)||H.a6(n,o)))return!1}}return H.lp(a.named,b.named)},
oc:function(a){var z=$.d9
return"Instance of "+(z==null?"<Unknown>":z.$1(a))},
o8:function(a){return H.ax(a)},
o7:function(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
lU:function(a){var z,y,x,w,v,u
z=$.d9.$1(a)
y=$.c8[z]
if(y!=null){Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}x=$.cd[z]
if(x!=null)return x
w=init.interceptorsByTag[z]
if(w==null){z=$.fb.$2(a,z)
if(z!=null){y=$.c8[z]
if(y!=null){Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}x=$.cd[z]
if(x!=null)return x
w=init.interceptorsByTag[z]}}if(w==null)return
x=w.prototype
v=z[0]
if(v==="!"){y=H.db(x)
$.c8[z]=y
Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}if(v==="~"){$.cd[z]=x
return x}if(v==="-"){u=H.db(x)
Object.defineProperty(Object.getPrototypeOf(a),init.dispatchPropertyName,{value:u,enumerable:false,writable:true,configurable:true})
return u.i}if(v==="+")return H.fm(a,x)
if(v==="*")throw H.c(new P.cS(z))
if(init.leafTags[z]===true){u=H.db(x)
Object.defineProperty(Object.getPrototypeOf(a),init.dispatchPropertyName,{value:u,enumerable:false,writable:true,configurable:true})
return u.i}else return H.fm(a,x)},
fm:function(a,b){var z=Object.getPrototypeOf(a)
Object.defineProperty(z,init.dispatchPropertyName,{value:J.ce(b,z,null,null),enumerable:false,writable:true,configurable:true})
return b},
db:function(a){return J.ce(a,!1,null,!!a.$isY)},
lV:function(a,b,c){var z=b.prototype
if(init.leafTags[a]===true)return J.ce(z,!1,null,!!z.$isY)
else return J.ce(z,c,null,null)},
lK:function(){if(!0===$.da)return
$.da=!0
H.lL()},
lL:function(){var z,y,x,w,v,u,t,s
$.c8=Object.create(null)
$.cd=Object.create(null)
H.lG()
z=init.interceptorsByTag
y=Object.getOwnPropertyNames(z)
if(typeof window!="undefined"){window
x=function(){}
for(w=0;w<y.length;++w){v=y[w]
u=$.fn.$1(v)
if(u!=null){t=H.lV(v,z[v],u)
if(t!=null){Object.defineProperty(u,init.dispatchPropertyName,{value:t,enumerable:false,writable:true,configurable:true})
x.prototype=u}}}}for(w=0;w<y.length;++w){v=y[w]
if(/^[A-Za-z_]/.test(v)){s=z[v]
z["!"+v]=s
z["~"+v]=s
z["-"+v]=s
z["+"+v]=s
z["*"+v]=s}}},
lG:function(){var z,y,x,w,v,u,t
z=C.C()
z=H.aV(C.z,H.aV(C.E,H.aV(C.p,H.aV(C.p,H.aV(C.D,H.aV(C.A,H.aV(C.B(C.q),z)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){y=dartNativeDispatchHooksTransformer
if(typeof y=="function")y=[y]
if(y.constructor==Array)for(x=0;x<y.length;++x){w=y[x]
if(typeof w=="function")z=w(z)||z}}v=z.getTag
u=z.getUnknownTag
t=z.prototypeForTag
$.d9=new H.lH(v)
$.fb=new H.lI(u)
$.fn=new H.lJ(t)},
aV:function(a,b){return a(b)||b},
m4:function(a,b,c){var z=a.indexOf(b,c)
return z>=0},
dc:function(a,b,c){var z,y,x
H.d5(c)
if(b==="")if(a==="")return c
else{z=a.length
y=H.b(c)
for(x=0;x<z;++x)y=y+a[x]+H.b(c)
return y.charCodeAt(0)==0?y:y}else return a.replace(new RegExp(b.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&"),'g'),c.replace(/\$/g,"$$$$"))},
ha:{"^":"eG;a,$ti",$aseG:I.Q,$asI:I.Q,$isI:1},
h9:{"^":"e;",
gD:function(a){return this.gi(this)===0},
gT:function(a){return this.gi(this)!==0},
j:function(a){return P.cK(this)},
l:function(a,b,c){return H.dz()},
A:function(a,b){return H.dz()},
$isI:1},
hb:{"^":"h9;a,b,c,$ti",
gi:function(a){return this.a},
M:function(a){if(typeof a!=="string")return!1
if("__proto__"===a)return!1
return this.b.hasOwnProperty(a)},
h:function(a,b){if(!this.M(b))return
return this.dF(b)},
dF:function(a){return this.b[a]},
J:function(a,b){var z,y,x,w
z=this.c
for(y=z.length,x=0;x<y;++x){w=z[x]
b.$2(w,this.dF(w))}}},
ii:{"^":"e;a,b,c,d,e,f",
geA:function(){var z=this.a
return z},
geH:function(){var z,y,x,w
if(this.c===1)return C.i
z=this.d
y=z.length-this.e.length
if(y===0)return C.i
x=[]
for(w=0;w<y;++w){if(w>=z.length)return H.a(z,w)
x.push(z[w])}x.fixed$length=Array
x.immutable$list=Array
return x},
geB:function(){var z,y,x,w,v,u,t,s,r
if(this.c!==0)return C.r
z=this.e
y=z.length
x=this.d
w=x.length-y
if(y===0)return C.r
v=P.bz
u=new H.a1(0,null,null,null,null,null,0,[v,null])
for(t=0;t<y;++t){if(t>=z.length)return H.a(z,t)
s=z[t]
r=w+t
if(r<0||r>=x.length)return H.a(x,r)
u.l(0,new H.cQ(s),x[r])}return new H.ha(u,[v,null])}},
jd:{"^":"e;a,b,c,d,e,f,r,x",
hX:function(a,b){var z=this.d
if(typeof b!=="number")return b.aj()
if(b<z)return
return this.b[3+b-z]},
w:{
eg:function(a){var z,y,x
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
a8:function(a){var z,y,x
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
al:function(a){var z,y,x,w,v,u
a=a.replace(String({}),'$receiver$').replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
z=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(z==null)z=[]
y=z.indexOf("\\$arguments\\$")
x=z.indexOf("\\$argumentsExpr\\$")
w=z.indexOf("\\$expr\\$")
v=z.indexOf("\\$method\\$")
u=z.indexOf("\\$receiver\\$")
return new H.jI(a.replace(new RegExp('\\\\\\$arguments\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$argumentsExpr\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$expr\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$method\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$receiver\\\\\\$','g'),'((?:x|[^x])*)'),y,x,w,v,u)},
c1:function(a){return function($expr$){var $argumentsExpr$='$arguments$'
try{$expr$.$method$($argumentsExpr$)}catch(z){return z.message}}(a)},
eB:function(a){return function($expr$){try{$expr$.$method$}catch(z){return z.message}}(a)}}},
e3:{"^":"P;a,b",
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
cG:function(a,b){var z,y
z=b==null
y=z?null:b.method
return new H.it(a,y,z?null:b.receiver)}}},
jK:{"^":"P;a",
j:function(a){var z=this.a
return z.length===0?"Error":"Error: "+z}},
m6:{"^":"f:0;a",
$1:function(a){if(!!J.j(a).$isP)if(a.$thrownJsError==null)a.$thrownJsError=this.a
return a}},
eU:{"^":"e;a,b",
j:function(a){var z,y
z=this.b
if(z!=null)return z
z=this.a
y=z!==null&&typeof z==="object"?z.stack:null
z=y==null?"":y
this.b=z
return z}},
lN:{"^":"f:2;a",
$0:function(){return this.a.$0()}},
lO:{"^":"f:2;a,b",
$0:function(){return this.a.$1(this.b)}},
lP:{"^":"f:2;a,b,c",
$0:function(){return this.a.$2(this.b,this.c)}},
lQ:{"^":"f:2;a,b,c,d",
$0:function(){return this.a.$3(this.b,this.c,this.d)}},
lR:{"^":"f:2;a,b,c,d,e",
$0:function(){return this.a.$4(this.b,this.c,this.d,this.e)}},
f:{"^":"e;",
j:function(a){return"Closure '"+H.c_(this).trim()+"'"},
geX:function(){return this},
$iscB:1,
geX:function(){return this}},
eq:{"^":"f;"},
jn:{"^":"eq;",
j:function(a){var z=this.$static_name
if(z==null)return"Closure of unknown static method"
return"Closure '"+z+"'"}},
cs:{"^":"eq;a,b,c,d",
F:function(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof H.cs))return!1
return this.a===b.a&&this.b===b.b&&this.c===b.c},
gI:function(a){var z,y
z=this.c
if(z==null)y=H.ax(this.a)
else y=typeof z!=="object"?J.a_(z):H.ax(z)
return J.fr(y,H.ax(this.b))},
j:function(a){var z=this.c
if(z==null)z=this.a
return"Closure '"+H.b(this.d)+"' of "+H.bZ(z)},
w:{
ct:function(a){return a.a},
dv:function(a){return a.c},
h_:function(){var z=$.b1
if(z==null){z=H.bL("self")
$.b1=z}return z},
bL:function(a){var z,y,x,w,v
z=new H.cs("self","target","receiver","name")
y=Object.getOwnPropertyNames(z)
y.fixed$length=Array
x=y
for(y=x.length,w=0;w<y;++w){v=x[w]
if(z[v]===a)return v}}}},
h0:{"^":"P;a",
j:function(a){return this.a},
w:{
dw:function(a,b){return new H.h0("CastError: Casting value of type '"+a+"' to incompatible type '"+b+"'")}}},
jf:{"^":"P;a",
j:function(a){return"RuntimeError: "+H.b(this.a)}},
a1:{"^":"e;a,b,c,d,e,f,r,$ti",
gi:function(a){return this.a},
gD:function(a){return this.a===0},
gT:function(a){return!this.gD(this)},
gab:function(){return new H.iA(this,[H.F(this,0)])},
gd6:function(a){return H.bV(this.gab(),new H.is(this),H.F(this,0),H.F(this,1))},
M:function(a){var z,y
if(typeof a==="string"){z=this.b
if(z==null)return!1
return this.dC(z,a)}else if(typeof a==="number"&&(a&0x3ffffff)===a){y=this.c
if(y==null)return!1
return this.dC(y,a)}else return this.ip(a)},
ip:function(a){var z=this.d
if(z==null)return!1
return this.ba(this.bu(z,this.b9(a)),a)>=0},
h:function(a,b){var z,y,x
if(typeof b==="string"){z=this.b
if(z==null)return
y=this.aY(z,b)
return y==null?null:y.gax()}else if(typeof b==="number"&&(b&0x3ffffff)===b){x=this.c
if(x==null)return
y=this.aY(x,b)
return y==null?null:y.gax()}else return this.iq(b)},
iq:function(a){var z,y,x
z=this.d
if(z==null)return
y=this.bu(z,this.b9(a))
x=this.ba(y,a)
if(x<0)return
return y[x].gax()},
l:function(a,b,c){var z,y,x,w,v,u
if(typeof b==="string"){z=this.b
if(z==null){z=this.co()
this.b=z}this.dk(z,b,c)}else if(typeof b==="number"&&(b&0x3ffffff)===b){y=this.c
if(y==null){y=this.co()
this.c=y}this.dk(y,b,c)}else{x=this.d
if(x==null){x=this.co()
this.d=x}w=this.b9(b)
v=this.bu(x,w)
if(v==null)this.cw(x,w,[this.cp(b,c)])
else{u=this.ba(v,b)
if(u>=0)v[u].sax(c)
else v.push(this.cp(b,c))}}},
A:function(a,b){if(typeof b==="string")return this.dV(this.b,b)
else if(typeof b==="number"&&(b&0x3ffffff)===b)return this.dV(this.c,b)
else return this.ir(b)},
ir:function(a){var z,y,x,w
z=this.d
if(z==null)return
y=this.bu(z,this.b9(a))
x=this.ba(y,a)
if(x<0)return
w=y.splice(x,1)[0]
this.e3(w)
return w.gax()},
a7:function(a){if(this.a>0){this.f=null
this.e=null
this.d=null
this.c=null
this.b=null
this.a=0
this.r=this.r+1&67108863}},
J:function(a,b){var z,y
z=this.e
y=this.r
for(;z!=null;){b.$2(z.a,z.b)
if(y!==this.r)throw H.c(new P.a7(this))
z=z.c}},
dk:function(a,b,c){var z=this.aY(a,b)
if(z==null)this.cw(a,b,this.cp(b,c))
else z.sax(c)},
dV:function(a,b){var z
if(a==null)return
z=this.aY(a,b)
if(z==null)return
this.e3(z)
this.dD(a,b)
return z.gax()},
cp:function(a,b){var z,y
z=new H.iz(a,b,null,null)
if(this.e==null){this.f=z
this.e=z}else{y=this.f
z.d=y
y.c=z
this.f=z}++this.a
this.r=this.r+1&67108863
return z},
e3:function(a){var z,y
z=a.ghe()
y=a.ghc()
if(z==null)this.e=y
else z.c=y
if(y==null)this.f=z
else y.d=z;--this.a
this.r=this.r+1&67108863},
b9:function(a){return J.a_(a)&0x3ffffff},
ba:function(a,b){var z,y
if(a==null)return-1
z=a.length
for(y=0;y<z;++y)if(J.J(a[y].geu(),b))return y
return-1},
j:function(a){return P.cK(this)},
aY:function(a,b){return a[b]},
bu:function(a,b){return a[b]},
cw:function(a,b,c){a[b]=c},
dD:function(a,b){delete a[b]},
dC:function(a,b){return this.aY(a,b)!=null},
co:function(){var z=Object.create(null)
this.cw(z,"<non-identifier-key>",z)
this.dD(z,"<non-identifier-key>")
return z},
$isi6:1,
$isI:1},
is:{"^":"f:0;a",
$1:[function(a){return this.a.h(0,a)},null,null,2,0,null,18,"call"]},
iz:{"^":"e;eu:a<,ax:b@,hc:c<,he:d<"},
iA:{"^":"i;a,$ti",
gi:function(a){return this.a.a},
gD:function(a){return this.a.a===0},
gH:function(a){var z,y
z=this.a
y=new H.iB(z,z.r,null,null)
y.c=z.e
return y}},
iB:{"^":"e;a,b,c,d",
gt:function(){return this.d},
n:function(){var z=this.a
if(this.b!==z.r)throw H.c(new P.a7(z))
else{z=this.c
if(z==null){this.d=null
return!1}else{this.d=z.a
this.c=z.c
return!0}}}},
lH:{"^":"f:0;a",
$1:function(a){return this.a(a)}},
lI:{"^":"f:10;a",
$2:function(a,b){return this.a(a,b)}},
lJ:{"^":"f:11;a",
$1:function(a){return this.a(a)}},
io:{"^":"e;a,b,c,d",
j:function(a){return"RegExp/"+this.a+"/"},
ghb:function(){var z=this.d
if(z!=null)return z
z=this.b
z=H.dU(this.a+"|()",z.multiline,!z.ignoreCase,!0)
this.d=z
return z},
fZ:function(a,b){var z,y
z=this.ghb()
z.lastIndex=b
y=z.exec(a)
if(y==null)return
if(0>=y.length)return H.a(y,-1)
if(y.pop()!=null)return
return new H.kF(this,y)},
ez:function(a,b,c){if(c>b.length)throw H.c(P.G(c,0,b.length,null,null))
return this.fZ(b,c)},
w:{
dU:function(a,b,c,d){var z,y,x,w
z=b?"m":""
y=c?"":"i"
x=d?"g":""
w=function(e,f){try{return new RegExp(e,f)}catch(v){return v}}(a,z+y+x)
if(w instanceof RegExp)return w
throw H.c(new P.bP("Illegal RegExp pattern ("+String(w)+")",a,null))}}},
kF:{"^":"e;a,b",
h:function(a,b){var z=this.b
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]}},
js:{"^":"e;a,b,c",
h:function(a,b){if(b!==0)H.B(P.b9(b,null,null))
return this.c}}}],["","",,H,{"^":"",
lB:function(a){var z=H.p(a?Object.keys(a):[],[null])
z.fixed$length=Array
return z}}],["","",,H,{"^":"",
m0:function(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof window=="object")return
if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)}}],["","",,H,{"^":"",dW:{"^":"k;",$isdW:1,"%":"ArrayBuffer"},bY:{"^":"k;",
h5:function(a,b,c,d){var z=P.G(b,0,c,d,null)
throw H.c(z)},
ds:function(a,b,c,d){if(b>>>0!==b||b>c)this.h5(a,b,c,d)},
$isbY:1,
$isa8:1,
"%":";ArrayBufferView;cL|dX|dZ|bX|dY|e_|aw"},n5:{"^":"bY;",$isa8:1,"%":"DataView"},cL:{"^":"bY;",
gi:function(a){return a.length},
e_:function(a,b,c,d,e){var z,y,x
z=a.length
this.ds(a,b,z,"start")
this.ds(a,c,z,"end")
if(b>c)throw H.c(P.G(b,0,c,null,null))
y=c-b
x=d.length
if(x-e<y)throw H.c(new P.a4("Not enough elements"))
if(e!==0||x!==y)d=d.subarray(e,e+y)
a.set(d,b)},
$isY:1,
$asY:I.Q,
$isS:1,
$asS:I.Q},bX:{"^":"dZ;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
l:function(a,b,c){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
a[b]=c},
X:function(a,b,c,d,e){if(!!J.j(d).$isbX){this.e_(a,b,c,d,e)
return}this.df(a,b,c,d,e)}},dX:{"^":"cL+W;",$asY:I.Q,$asS:I.Q,
$ash:function(){return[P.ap]},
$asi:function(){return[P.ap]},
$ish:1,
$isi:1},dZ:{"^":"dX+dM;",$asY:I.Q,$asS:I.Q,
$ash:function(){return[P.ap]},
$asi:function(){return[P.ap]}},aw:{"^":"e_;",
l:function(a,b,c){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
a[b]=c},
X:function(a,b,c,d,e){if(!!J.j(d).$isaw){this.e_(a,b,c,d,e)
return}this.df(a,b,c,d,e)},
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]}},dY:{"^":"cL+W;",$asY:I.Q,$asS:I.Q,
$ash:function(){return[P.y]},
$asi:function(){return[P.y]},
$ish:1,
$isi:1},e_:{"^":"dY+dM;",$asY:I.Q,$asS:I.Q,
$ash:function(){return[P.y]},
$asi:function(){return[P.y]}},n6:{"^":"bX;",$isa8:1,$ish:1,
$ash:function(){return[P.ap]},
$isi:1,
$asi:function(){return[P.ap]},
"%":"Float32Array"},n7:{"^":"bX;",$isa8:1,$ish:1,
$ash:function(){return[P.ap]},
$isi:1,
$asi:function(){return[P.ap]},
"%":"Float64Array"},n8:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa8:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Int16Array"},n9:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa8:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Int32Array"},na:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa8:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Int8Array"},nb:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa8:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Uint16Array"},nc:{"^":"aw;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa8:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"Uint32Array"},nd:{"^":"aw;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa8:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":"CanvasPixelArray|Uint8ClampedArray"},ne:{"^":"aw;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)H.B(H.M(a,b))
return a[b]},
$isa8:1,
$ish:1,
$ash:function(){return[P.y]},
$isi:1,
$asi:function(){return[P.y]},
"%":";Uint8Array"}}],["","",,P,{"^":"",
jO:function(){var z,y,x
z={}
if(self.scheduleImmediate!=null)return P.lq()
if(self.MutationObserver!=null&&self.document!=null){y=self.document.createElement("div")
x=self.document.createElement("span")
z.a=null
new self.MutationObserver(H.aW(new P.jQ(z),1)).observe(y,{childList:true})
return new P.jP(z,y,x)}else if(self.setImmediate!=null)return P.lr()
return P.ls()},
nO:[function(a){++init.globalState.f.b
self.scheduleImmediate(H.aW(new P.jR(a),0))},"$1","lq",2,0,4],
nP:[function(a){++init.globalState.f.b
self.setImmediate(H.aW(new P.jS(a),0))},"$1","lr",2,0,4],
nQ:[function(a){P.cR(C.o,a)},"$1","ls",2,0,4],
lf:function(a,b,c){if(H.aI(a,{func:1,args:[P.b7,P.b7]}))return a.$2(b,c)
else return a.$1(b)},
f3:function(a,b){if(H.aI(a,{func:1,args:[P.b7,P.b7]})){b.toString
return a}else{b.toString
return a}},
lh:function(){var z,y
for(;z=$.aS,z!=null;){$.bd=null
y=z.gZ()
$.aS=y
if(y==null)$.bc=null
z.gee().$0()}},
o6:[function(){$.d3=!0
try{P.lh()}finally{$.bd=null
$.d3=!1
if($.aS!=null)$.$get$cU().$1(P.ff())}},"$0","ff",0,0,1],
f8:function(a){var z=new P.eH(a,null)
if($.aS==null){$.bc=z
$.aS=z
if(!$.d3)$.$get$cU().$1(P.ff())}else{$.bc.b=z
$.bc=z}},
ll:function(a){var z,y,x
z=$.aS
if(z==null){P.f8(a)
$.bd=$.bc
return}y=new P.eH(a,null)
x=$.bd
if(x==null){y.b=z
$.bd=y
$.aS=y}else{y.b=x.b
x.b=y
$.bd=y
if(y.b==null)$.bc=y}},
fo:function(a){var z=$.x
if(C.c===z){P.aU(null,null,C.c,a)
return}z.toString
P.aU(null,null,z,z.cD(a,!0))},
f7:function(a){var z,y,x,w
if(a==null)return
try{a.$0()}catch(x){z=H.D(x)
y=H.Z(x)
w=$.x
w.toString
P.aT(null,null,w,z,y)}},
o4:[function(a){},"$1","lt",2,0,19,2],
li:[function(a,b){var z=$.x
z.toString
P.aT(null,null,z,a,b)},function(a){return P.li(a,null)},"$2","$1","lu",2,2,3,1],
o5:[function(){},"$0","fe",0,0,1],
eX:function(a,b,c){$.x.toString
a.aD(b,c)},
jA:function(a,b){var z=$.x
if(z===C.c){z.toString
return P.cR(a,b)}return P.cR(a,z.cD(b,!0))},
cR:function(a,b){var z=C.f.bE(a.a,1000)
return H.jx(z<0?0:z,b)},
jN:function(){return $.x},
aT:function(a,b,c,d,e){var z={}
z.a=d
P.ll(new P.lk(z,e))},
f4:function(a,b,c,d){var z,y
y=$.x
if(y===c)return d.$0()
$.x=c
z=y
try{y=d.$0()
return y}finally{$.x=z}},
f6:function(a,b,c,d,e){var z,y
y=$.x
if(y===c)return d.$1(e)
$.x=c
z=y
try{y=d.$1(e)
return y}finally{$.x=z}},
f5:function(a,b,c,d,e,f){var z,y
y=$.x
if(y===c)return d.$2(e,f)
$.x=c
z=y
try{y=d.$2(e,f)
return y}finally{$.x=z}},
aU:function(a,b,c,d){var z=C.c!==c
if(z)d=c.cD(d,!(!z||!1))
P.f8(d)},
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
jU:{"^":"eJ;a,$ti"},
jV:{"^":"k_;aU:y@,ad:z@,bq:Q@,x,a,b,c,d,e,f,r,$ti",
h_:function(a){return(this.y&1)===a},
hB:function(){this.y^=1},
gh7:function(){return(this.y&2)!==0},
hx:function(){this.y|=4},
ghj:function(){return(this.y&4)!==0},
bw:[function(){},"$0","gbv",0,0,1],
by:[function(){},"$0","gbx",0,0,1]},
cV:{"^":"e;aa:c<,$ti",
gbb:function(){return!1},
gaZ:function(){return this.c<4},
fX:function(){var z=this.r
if(z!=null)return z
z=new P.an(0,$.x,null,[null])
this.r=z
return z},
aP:function(a){var z
a.saU(this.c&1)
z=this.e
this.e=a
a.sad(null)
a.sbq(z)
if(z==null)this.d=a
else z.sad(a)},
dW:function(a){var z,y
z=a.gbq()
y=a.gad()
if(z==null)this.d=y
else z.sad(y)
if(y==null)this.e=z
else y.sbq(z)
a.sbq(a)
a.sad(a)},
hA:function(a,b,c,d){var z,y,x
if((this.c&4)!==0){if(c==null)c=P.fe()
z=new P.k5($.x,0,c,this.$ti)
z.dZ()
return z}z=$.x
y=d?1:0
x=new P.jV(0,null,null,this,null,null,null,z,y,null,null,this.$ti)
x.di(a,b,c,d,H.F(this,0))
x.Q=x
x.z=x
this.aP(x)
z=this.d
y=this.e
if(z==null?y==null:z===y)P.f7(this.a)
return x},
hg:function(a){if(a.gad()===a)return
if(a.gh7())a.hx()
else{this.dW(a)
if((this.c&2)===0&&this.d==null)this.c6()}return},
hh:function(a){},
hi:function(a){},
bp:["fn",function(){if((this.c&4)!==0)return new P.a4("Cannot add new events after calling close")
return new P.a4("Cannot add new events while doing an addStream")}],
C:[function(a,b){if(!this.gaZ())throw H.c(this.bp())
this.bB(b)},"$1","ghD",2,0,function(){return H.bf(function(a){return{func:1,v:true,args:[a]}},this.$receiver,"cV")}],
hG:[function(a,b){if(!this.gaZ())throw H.c(this.bp())
$.x.toString
this.bC(a,b)},function(a){return this.hG(a,null)},"iZ","$2","$1","ghF",2,2,3,1],
ei:function(a){var z
if((this.c&4)!==0)return this.r
if(!this.gaZ())throw H.c(this.bp())
this.c|=4
z=this.fX()
this.b1()
return z},
ck:function(a){var z,y,x,w
z=this.c
if((z&2)!==0)throw H.c(new P.a4("Cannot fire new event. Controller is already firing an event"))
y=this.d
if(y==null)return
x=z&1
this.c=z^3
for(;y!=null;)if(y.h_(x)){y.saU(y.gaU()|2)
a.$1(y)
y.hB()
w=y.gad()
if(y.ghj())this.dW(y)
y.saU(y.gaU()&4294967293)
y=w}else y=y.gad()
this.c&=4294967293
if(this.d==null)this.c6()},
c6:function(){if((this.c&4)!==0&&this.r.a===0)this.r.dq(null)
P.f7(this.b)}},
c6:{"^":"cV;a,b,c,d,e,f,r,$ti",
gaZ:function(){return P.cV.prototype.gaZ.call(this)===!0&&(this.c&2)===0},
bp:function(){if((this.c&2)!==0)return new P.a4("Cannot fire new event. Controller is already firing an event")
return this.fn()},
bB:function(a){var z=this.d
if(z==null)return
if(z===this.e){this.c|=2
z.aQ(a)
this.c&=4294967293
if(this.d==null)this.c6()
return}this.ck(new P.l1(this,a))},
bC:function(a,b){if(this.d==null)return
this.ck(new P.l3(this,a,b))},
b1:function(){if(this.d!=null)this.ck(new P.l2(this))
else this.r.dq(null)}},
l1:{"^":"f;a,b",
$1:function(a){a.aQ(this.b)},
$S:function(){return H.bf(function(a){return{func:1,args:[[P.aG,a]]}},this.a,"c6")}},
l3:{"^":"f;a,b,c",
$1:function(a){a.aD(this.b,this.c)},
$S:function(){return H.bf(function(a){return{func:1,args:[[P.aG,a]]}},this.a,"c6")}},
l2:{"^":"f;a",
$1:function(a){a.dn()},
$S:function(){return H.bf(function(a){return{func:1,args:[[P.aG,a]]}},this.a,"c6")}},
jZ:{"^":"e;$ti"},
l4:{"^":"jZ;a,$ti"},
eN:{"^":"e;ae:a@,N:b>,c,ee:d<,e",
gaq:function(){return this.b.b},
geq:function(){return(this.c&1)!==0},
gil:function(){return(this.c&2)!==0},
gep:function(){return this.c===8},
gim:function(){return this.e!=null},
ij:function(a){return this.b.b.d0(this.d,a)},
iz:function(a){if(this.c!==6)return!0
return this.b.b.d0(this.d,J.bi(a))},
eo:function(a){var z,y,x
z=this.e
y=J.m(a)
x=this.b.b
if(H.aI(z,{func:1,args:[,,]}))return x.iM(z,y.gau(a),a.gak())
else return x.d0(z,y.gau(a))},
ik:function(){return this.b.b.eL(this.d)}},
an:{"^":"e;aa:a<,aq:b<,aF:c<,$ti",
gh6:function(){return this.a===2},
gcn:function(){return this.a>=4},
gh4:function(){return this.a===8},
hu:function(a){this.a=2
this.c=a},
eP:function(a,b){var z,y
z=$.x
if(z!==C.c){z.toString
if(b!=null)b=P.f3(b,z)}y=new P.an(0,$.x,null,[null])
this.aP(new P.eN(null,y,b==null?1:3,a,b))
return y},
eO:function(a){return this.eP(a,null)},
eU:function(a){var z,y
z=$.x
y=new P.an(0,z,null,this.$ti)
if(z!==C.c)z.toString
this.aP(new P.eN(null,y,8,a,null))
return y},
hw:function(){this.a=1},
fO:function(){this.a=0},
gan:function(){return this.c},
gfL:function(){return this.c},
hy:function(a){this.a=4
this.c=a},
hv:function(a){this.a=8
this.c=a},
dt:function(a){this.a=a.gaa()
this.c=a.gaF()},
aP:function(a){var z,y
z=this.a
if(z<=1){a.a=this.c
this.c=a}else{if(z===2){y=this.c
if(!y.gcn()){y.aP(a)
return}this.a=y.gaa()
this.c=y.gaF()}z=this.b
z.toString
P.aU(null,null,z,new P.ke(this,a))}},
dU:function(a){var z,y,x,w,v
z={}
z.a=a
if(a==null)return
y=this.a
if(y<=1){x=this.c
this.c=a
if(x!=null){for(w=a;w.gae()!=null;)w=w.gae()
w.sae(x)}}else{if(y===2){v=this.c
if(!v.gcn()){v.dU(a)
return}this.a=v.gaa()
this.c=v.gaF()}z.a=this.dX(a)
y=this.b
y.toString
P.aU(null,null,y,new P.kk(z,this))}},
aE:function(){var z=this.c
this.c=null
return this.dX(z)},
dX:function(a){var z,y,x
for(z=a,y=null;z!=null;y=z,z=x){x=z.gae()
z.sae(y)}return y},
br:function(a){var z,y
z=this.$ti
if(H.bH(a,"$isaE",z,"$asaE"))if(H.bH(a,"$isan",z,null))P.c4(a,this)
else P.eO(a,this)
else{y=this.aE()
this.a=4
this.c=a
P.aQ(this,y)}},
cb:[function(a,b){var z=this.aE()
this.a=8
this.c=new P.bJ(a,b)
P.aQ(this,z)},function(a){return this.cb(a,null)},"iV","$2","$1","gdB",2,2,3,1,4,6],
dq:function(a){var z
if(H.bH(a,"$isaE",this.$ti,"$asaE")){this.fK(a)
return}this.a=1
z=this.b
z.toString
P.aU(null,null,z,new P.kf(this,a))},
fK:function(a){var z
if(H.bH(a,"$isan",this.$ti,null)){if(a.a===8){this.a=1
z=this.b
z.toString
P.aU(null,null,z,new P.kj(this,a))}else P.c4(a,this)
return}P.eO(a,this)},
fF:function(a,b){this.a=4
this.c=a},
$isaE:1,
w:{
eO:function(a,b){var z,y,x
b.hw()
try{a.eP(new P.kg(b),new P.kh(b))}catch(x){z=H.D(x)
y=H.Z(x)
P.fo(new P.ki(b,z,y))}},
c4:function(a,b){var z
for(;a.gh6();)a=a.gfL()
if(a.gcn()){z=b.aE()
b.dt(a)
P.aQ(b,z)}else{z=b.gaF()
b.hu(a)
a.dU(z)}},
aQ:function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o
z={}
z.a=a
for(y=a;!0;){x={}
w=y.gh4()
if(b==null){if(w){v=z.a.gan()
y=z.a.gaq()
u=J.bi(v)
t=v.gak()
y.toString
P.aT(null,null,y,u,t)}return}for(;b.gae()!=null;b=s){s=b.gae()
b.sae(null)
P.aQ(z.a,b)}r=z.a.gaF()
x.a=w
x.b=r
y=!w
if(!y||b.geq()||b.gep()){q=b.gaq()
if(w){u=z.a.gaq()
u.toString
u=u==null?q==null:u===q
if(!u)q.toString
else u=!0
u=!u}else u=!1
if(u){v=z.a.gan()
y=z.a.gaq()
u=J.bi(v)
t=v.gak()
y.toString
P.aT(null,null,y,u,t)
return}p=$.x
if(p==null?q!=null:p!==q)$.x=q
else p=null
if(b.gep())new P.kn(z,x,w,b).$0()
else if(y){if(b.geq())new P.km(x,b,r).$0()}else if(b.gil())new P.kl(z,x,b).$0()
if(p!=null)$.x=p
y=x.b
if(!!J.j(y).$isaE){o=J.dk(b)
if(y.a>=4){b=o.aE()
o.dt(y)
z.a=y
continue}else P.c4(y,o)
return}}o=J.dk(b)
b=o.aE()
y=x.a
u=x.b
if(!y)o.hy(u)
else o.hv(u)
z.a=o
y=o}}}},
ke:{"^":"f:2;a,b",
$0:function(){P.aQ(this.a,this.b)}},
kk:{"^":"f:2;a,b",
$0:function(){P.aQ(this.b,this.a.a)}},
kg:{"^":"f:0;a",
$1:[function(a){var z=this.a
z.fO()
z.br(a)},null,null,2,0,null,2,"call"]},
kh:{"^":"f:13;a",
$2:[function(a,b){this.a.cb(a,b)},function(a){return this.$2(a,null)},"$1",null,null,null,2,2,null,1,4,6,"call"]},
ki:{"^":"f:2;a,b,c",
$0:function(){this.a.cb(this.b,this.c)}},
kf:{"^":"f:2;a,b",
$0:function(){var z,y
z=this.a
y=z.aE()
z.a=4
z.c=this.b
P.aQ(z,y)}},
kj:{"^":"f:2;a,b",
$0:function(){P.c4(this.b,this.a)}},
kn:{"^":"f:1;a,b,c,d",
$0:function(){var z,y,x,w,v,u,t
z=null
try{z=this.d.ik()}catch(w){y=H.D(w)
x=H.Z(w)
if(this.c){v=J.bi(this.a.a.gan())
u=y
u=v==null?u==null:v===u
v=u}else v=!1
u=this.b
if(v)u.b=this.a.a.gan()
else u.b=new P.bJ(y,x)
u.a=!0
return}if(!!J.j(z).$isaE){if(z instanceof P.an&&z.gaa()>=4){if(z.gaa()===8){v=this.b
v.b=z.gaF()
v.a=!0}return}t=this.a.a
v=this.b
v.b=z.eO(new P.ko(t))
v.a=!1}}},
ko:{"^":"f:0;a",
$1:[function(a){return this.a},null,null,2,0,null,5,"call"]},
km:{"^":"f:1;a,b,c",
$0:function(){var z,y,x,w
try{this.a.b=this.b.ij(this.c)}catch(x){z=H.D(x)
y=H.Z(x)
w=this.a
w.b=new P.bJ(z,y)
w.a=!0}}},
kl:{"^":"f:1;a,b,c",
$0:function(){var z,y,x,w,v,u,t,s
try{z=this.a.a.gan()
w=this.c
if(w.iz(z)===!0&&w.gim()){v=this.b
v.b=w.eo(z)
v.a=!1}}catch(u){y=H.D(u)
x=H.Z(u)
w=this.a
v=J.bi(w.a.gan())
t=y
s=this.b
if(v==null?t==null:v===t)s.b=w.a.gan()
else s.b=new P.bJ(y,x)
s.a=!0}}},
eH:{"^":"e;ee:a<,Z:b@"},
ad:{"^":"e;$ti",
af:function(a,b){return new P.kE(b,this,[H.H(this,"ad",0),null])},
ie:function(a,b){return new P.kp(a,b,this,[H.H(this,"ad",0)])},
eo:function(a){return this.ie(a,null)},
gi:function(a){var z,y
z={}
y=new P.an(0,$.x,null,[P.y])
z.a=0
this.a1(new P.jo(z),!0,new P.jp(z,y),y.gdB())
return y},
aL:function(a){var z,y,x
z=H.H(this,"ad",0)
y=H.p([],[z])
x=new P.an(0,$.x,null,[[P.h,z]])
this.a1(new P.jq(this,y),!0,new P.jr(y,x),x.gdB())
return x}},
jo:{"^":"f:0;a",
$1:[function(a){++this.a.a},null,null,2,0,null,5,"call"]},
jp:{"^":"f:2;a,b",
$0:[function(){this.b.br(this.a.a)},null,null,0,0,null,"call"]},
jq:{"^":"f;a,b",
$1:[function(a){this.b.push(a)},null,null,2,0,null,11,"call"],
$S:function(){return H.bf(function(a){return{func:1,args:[a]}},this.a,"ad")}},
jr:{"^":"f:2;a,b",
$0:[function(){this.b.br(this.a)},null,null,0,0,null,"call"]},
em:{"^":"e;$ti"},
eJ:{"^":"kX;a,$ti",
gI:function(a){return(H.ax(this.a)^892482866)>>>0},
F:function(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof P.eJ))return!1
return b.a===this.a}},
k_:{"^":"aG;$ti",
cq:function(){return this.x.hg(this)},
bw:[function(){this.x.hh(this)},"$0","gbv",0,0,1],
by:[function(){this.x.hi(this)},"$0","gbx",0,0,1]},
aG:{"^":"e;aq:d<,aa:e<,$ti",
bf:function(a,b){var z=this.e
if((z&8)!==0)return
this.e=(z+128|4)>>>0
if(z<128&&this.r!=null)this.r.ef()
if((z&4)===0&&(this.e&32)===0)this.dM(this.gbv())},
cU:function(a){return this.bf(a,null)},
cY:function(){var z=this.e
if((z&8)!==0)return
if(z>=128){z-=128
this.e=z
if(z<128){if((z&64)!==0){z=this.r
z=!z.gD(z)}else z=!1
if(z)this.r.bY(this)
else{z=(this.e&4294967291)>>>0
this.e=z
if((z&32)===0)this.dM(this.gbx())}}}},
aI:function(){var z=(this.e&4294967279)>>>0
this.e=z
if((z&8)===0)this.c7()
z=this.f
return z==null?$.$get$br():z},
gbb:function(){return this.e>=128},
c7:function(){var z=(this.e|8)>>>0
this.e=z
if((z&64)!==0)this.r.ef()
if((this.e&32)===0)this.r=null
this.f=this.cq()},
aQ:["fo",function(a){var z=this.e
if((z&8)!==0)return
if(z<32)this.bB(a)
else this.c5(new P.k2(a,null,[H.H(this,"aG",0)]))}],
aD:["fp",function(a,b){var z=this.e
if((z&8)!==0)return
if(z<32)this.bC(a,b)
else this.c5(new P.k4(a,b,null))}],
dn:function(){var z=this.e
if((z&8)!==0)return
z=(z|2)>>>0
this.e=z
if(z<32)this.b1()
else this.c5(C.w)},
bw:[function(){},"$0","gbv",0,0,1],
by:[function(){},"$0","gbx",0,0,1],
cq:function(){return},
c5:function(a){var z,y
z=this.r
if(z==null){z=new P.kY(null,null,0,[H.H(this,"aG",0)])
this.r=z}z.C(0,a)
y=this.e
if((y&64)===0){y=(y|64)>>>0
this.e=y
if(y<128)this.r.bY(this)}},
bB:function(a){var z=this.e
this.e=(z|32)>>>0
this.d.d1(this.a,a)
this.e=(this.e&4294967263)>>>0
this.c9((z&4)!==0)},
bC:function(a,b){var z,y
z=this.e
y=new P.jX(this,a,b)
if((z&1)!==0){this.e=(z|16)>>>0
this.c7()
z=this.f
if(!!J.j(z).$isaE&&z!==$.$get$br())z.eU(y)
else y.$0()}else{y.$0()
this.c9((z&4)!==0)}},
b1:function(){var z,y
z=new P.jW(this)
this.c7()
this.e=(this.e|16)>>>0
y=this.f
if(!!J.j(y).$isaE&&y!==$.$get$br())y.eU(z)
else z.$0()},
dM:function(a){var z=this.e
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
if(y)this.bw()
else this.by()
this.e=(this.e&4294967263)>>>0}z=this.e
if((z&64)!==0&&z<128)this.r.bY(this)},
di:function(a,b,c,d,e){var z,y
z=a==null?P.lt():a
y=this.d
y.toString
this.a=z
this.b=P.f3(b==null?P.lu():b,y)
this.c=c==null?P.fe():c}},
jX:{"^":"f:1;a,b,c",
$0:function(){var z,y,x,w,v,u
z=this.a
y=z.e
if((y&8)!==0&&(y&16)===0)return
z.e=(y|32)>>>0
y=z.b
x=H.aI(y,{func:1,args:[P.e,P.by]})
w=z.d
v=this.b
u=z.b
if(x)w.iN(u,v,this.c)
else w.d1(u,v)
z.e=(z.e&4294967263)>>>0}},
jW:{"^":"f:1;a",
$0:function(){var z,y
z=this.a
y=z.e
if((y&16)===0)return
z.e=(y|42)>>>0
z.d.d_(z.c)
z.e=(z.e&4294967263)>>>0}},
kX:{"^":"ad;$ti",
a1:function(a,b,c,d){return this.a.hA(a,d,c,!0===b)},
bd:function(a,b,c){return this.a1(a,null,b,c)}},
eK:{"^":"e;Z:a@"},
k2:{"^":"eK;b,a,$ti",
cV:function(a){a.bB(this.b)}},
k4:{"^":"eK;au:b>,ak:c<,a",
cV:function(a){a.bC(this.b,this.c)}},
k3:{"^":"e;",
cV:function(a){a.b1()},
gZ:function(){return},
sZ:function(a){throw H.c(new P.a4("No events after a done."))}},
kM:{"^":"e;aa:a<",
bY:function(a){var z=this.a
if(z===1)return
if(z>=1){this.a=1
return}P.fo(new P.kN(this,a))
this.a=1},
ef:function(){if(this.a===1)this.a=3}},
kN:{"^":"f:2;a,b",
$0:function(){var z,y,x,w
z=this.a
y=z.a
z.a=0
if(y===3)return
x=z.b
w=x.gZ()
z.b=w
if(w==null)z.c=null
x.cV(this.b)}},
kY:{"^":"kM;b,c,a,$ti",
gD:function(a){return this.c==null},
C:function(a,b){var z=this.c
if(z==null){this.c=b
this.b=b}else{z.sZ(b)
this.c=b}}},
k5:{"^":"e;aq:a<,aa:b<,c,$ti",
gbb:function(){return this.b>=4},
dZ:function(){if((this.b&2)!==0)return
var z=this.a
z.toString
P.aU(null,null,z,this.ght())
this.b=(this.b|2)>>>0},
bf:function(a,b){this.b+=4},
cU:function(a){return this.bf(a,null)},
cY:function(){var z=this.b
if(z>=4){z-=4
this.b=z
if(z<4&&(z&1)===0)this.dZ()}},
aI:function(){return $.$get$br()},
b1:[function(){var z=(this.b&4294967293)>>>0
this.b=z
if(z>=4)return
this.b=(z|1)>>>0
z=this.c
if(z!=null)this.a.d_(z)},"$0","ght",0,0,1]},
bB:{"^":"ad;$ti",
a1:function(a,b,c,d){return this.fR(a,d,c,!0===b)},
bd:function(a,b,c){return this.a1(a,null,b,c)},
fR:function(a,b,c,d){return P.kd(this,a,b,c,d,H.H(this,"bB",0),H.H(this,"bB",1))},
dN:function(a,b){b.aQ(a)},
dO:function(a,b,c){c.aD(a,b)},
$asad:function(a,b){return[b]}},
eM:{"^":"aG;x,y,a,b,c,d,e,f,r,$ti",
aQ:function(a){if((this.e&2)!==0)return
this.fo(a)},
aD:function(a,b){if((this.e&2)!==0)return
this.fp(a,b)},
bw:[function(){var z=this.y
if(z==null)return
z.cU(0)},"$0","gbv",0,0,1],
by:[function(){var z=this.y
if(z==null)return
z.cY()},"$0","gbx",0,0,1],
cq:function(){var z=this.y
if(z!=null){this.y=null
return z.aI()}return},
iW:[function(a){this.x.dN(a,this)},"$1","gh1",2,0,function(){return H.bf(function(a,b){return{func:1,v:true,args:[a]}},this.$receiver,"eM")},11],
iY:[function(a,b){this.x.dO(a,b,this)},"$2","gh3",4,0,14,4,6],
iX:[function(){this.dn()},"$0","gh2",0,0,1],
fE:function(a,b,c,d,e,f,g){this.y=this.x.a.bd(this.gh1(),this.gh2(),this.gh3())},
$asaG:function(a,b){return[b]},
w:{
kd:function(a,b,c,d,e,f,g){var z,y
z=$.x
y=e?1:0
y=new P.eM(a,null,null,null,null,z,y,null,null,[f,g])
y.di(b,c,d,e,g)
y.fE(a,b,c,d,e,f,g)
return y}}},
kE:{"^":"bB;b,a,$ti",
dN:function(a,b){var z,y,x,w
z=null
try{z=this.b.$1(a)}catch(w){y=H.D(w)
x=H.Z(w)
P.eX(b,y,x)
return}b.aQ(z)}},
kp:{"^":"bB;b,c,a,$ti",
dO:function(a,b,c){var z,y,x,w,v
z=!0
if(z===!0)try{P.lf(this.b,a,b)}catch(w){y=H.D(w)
x=H.Z(w)
v=y
if(v==null?a==null:v===a)c.aD(a,b)
else P.eX(c,y,x)
return}else c.aD(a,b)},
$asbB:function(a){return[a,a]},
$asad:null},
bJ:{"^":"e;au:a>,ak:b<",
j:function(a){return H.b(this.a)},
$isP:1},
l9:{"^":"e;"},
lk:{"^":"f:2;a,b",
$0:function(){var z,y,x
z=this.a
y=z.a
if(y==null){x=new P.e4()
z.a=x
z=x}else z=y
y=this.b
if(y==null)throw H.c(z)
x=H.c(z)
x.stack=J.C(y)
throw x}},
kP:{"^":"l9;",
d_:function(a){var z,y,x,w
try{if(C.c===$.x){x=a.$0()
return x}x=P.f4(null,null,this,a)
return x}catch(w){z=H.D(w)
y=H.Z(w)
x=P.aT(null,null,this,z,y)
return x}},
d1:function(a,b){var z,y,x,w
try{if(C.c===$.x){x=a.$1(b)
return x}x=P.f6(null,null,this,a,b)
return x}catch(w){z=H.D(w)
y=H.Z(w)
x=P.aT(null,null,this,z,y)
return x}},
iN:function(a,b,c){var z,y,x,w
try{if(C.c===$.x){x=a.$2(b,c)
return x}x=P.f5(null,null,this,a,b,c)
return x}catch(w){z=H.D(w)
y=H.Z(w)
x=P.aT(null,null,this,z,y)
return x}},
cD:function(a,b){if(b)return new P.kQ(this,a)
else return new P.kR(this,a)},
hM:function(a,b){return new P.kS(this,a)},
h:function(a,b){return},
eL:function(a){if($.x===C.c)return a.$0()
return P.f4(null,null,this,a)},
d0:function(a,b){if($.x===C.c)return a.$1(b)
return P.f6(null,null,this,a,b)},
iM:function(a,b,c){if($.x===C.c)return a.$2(b,c)
return P.f5(null,null,this,a,b,c)}},
kQ:{"^":"f:2;a,b",
$0:function(){return this.a.d_(this.b)}},
kR:{"^":"f:2;a,b",
$0:function(){return this.a.eL(this.b)}},
kS:{"^":"f:0;a,b",
$1:[function(a){return this.a.d1(this.b,a)},null,null,2,0,null,22,"call"]}}],["","",,P,{"^":"",
iC:function(a,b){return new H.a1(0,null,null,null,null,null,0,[a,b])},
bS:function(){return new H.a1(0,null,null,null,null,null,0,[null,null])},
au:function(a){return H.lC(a,new H.a1(0,null,null,null,null,null,0,[null,null]))},
ie:function(a,b,c){var z,y
if(P.d4(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}z=[]
y=$.$get$be()
y.push(a)
try{P.lg(a,z)}finally{if(0>=y.length)return H.a(y,-1)
y.pop()}y=P.en(b,z,", ")+c
return y.charCodeAt(0)==0?y:y},
bQ:function(a,b,c){var z,y,x
if(P.d4(a))return b+"..."+c
z=new P.aF(b)
y=$.$get$be()
y.push(a)
try{x=z
x.sk(P.en(x.gk(),a,", "))}finally{if(0>=y.length)return H.a(y,-1)
y.pop()}y=z
y.sk(y.gk()+c)
y=z.gk()
return y.charCodeAt(0)==0?y:y},
d4:function(a){var z,y
for(z=0;y=$.$get$be(),z<y.length;++z)if(a===y[z])return!0
return!1},
lg:function(a,b){var z,y,x,w,v,u,t,s,r,q
z=a.gH(a)
y=0
x=0
while(!0){if(!(y<80||x<3))break
if(!z.n())return
w=H.b(z.gt())
b.push(w)
y+=w.length+2;++x}if(!z.n()){if(x<=5)return
if(0>=b.length)return H.a(b,-1)
v=b.pop()
if(0>=b.length)return H.a(b,-1)
u=b.pop()}else{t=z.gt();++x
if(!z.n()){if(x<=4){b.push(H.b(t))
return}v=H.b(t)
if(0>=b.length)return H.a(b,-1)
u=b.pop()
y+=v.length+2}else{s=z.gt();++x
for(;z.n();t=s,s=r){r=z.gt();++x
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
a2:function(a,b,c,d){return new P.kx(0,null,null,null,null,null,0,[d])},
dV:function(a,b){var z,y,x
z=P.a2(null,null,null,b)
for(y=a.length,x=0;x<a.length;a.length===y||(0,H.A)(a),++x)z.C(0,a[x])
return z},
cK:function(a){var z,y,x
z={}
if(P.d4(a))return"{...}"
y=new P.aF("")
try{$.$get$be().push(a)
x=y
x.sk(x.gk()+"{")
z.a=!0
a.J(0,new P.iG(z,y))
z=y
z.sk(z.gk()+"}")}finally{z=$.$get$be()
if(0>=z.length)return H.a(z,-1)
z.pop()}z=y.gk()
return z.charCodeAt(0)==0?z:z},
eT:{"^":"a1;a,b,c,d,e,f,r,$ti",
b9:function(a){return H.m_(a)&0x3ffffff},
ba:function(a,b){var z,y,x
if(a==null)return-1
z=a.length
for(y=0;y<z;++y){x=a[y].geu()
if(x==null?b==null:x===b)return y}return-1},
w:{
bb:function(a,b){return new P.eT(0,null,null,null,null,null,0,[a,b])}}},
kx:{"^":"kq;a,b,c,d,e,f,r,$ti",
gH:function(a){var z=new P.bD(this,this.r,null,null)
z.c=this.e
return z},
gi:function(a){return this.a},
gD:function(a){return this.a===0},
gT:function(a){return this.a!==0},
K:function(a,b){var z,y
if(typeof b==="string"&&b!=="__proto__"){z=this.b
if(z==null)return!1
return z[b]!=null}else if(typeof b==="number"&&(b&0x3ffffff)===b){y=this.c
if(y==null)return!1
return y[b]!=null}else return this.fQ(b)},
fQ:function(a){var z=this.d
if(z==null)return!1
return this.bt(z[this.bs(a)],a)>=0},
cN:function(a){var z
if(!(typeof a==="string"&&a!=="__proto__"))z=typeof a==="number"&&(a&0x3ffffff)===a
else z=!0
if(z)return this.K(0,a)?a:null
else return this.h9(a)},
h9:function(a){var z,y,x
z=this.d
if(z==null)return
y=z[this.bs(a)]
x=this.bt(y,a)
if(x<0)return
return J.af(y,x).gcg()},
C:function(a,b){var z,y,x
if(typeof b==="string"&&b!=="__proto__"){z=this.b
if(z==null){y=Object.create(null)
y["<non-identifier-key>"]=y
delete y["<non-identifier-key>"]
this.b=y
z=y}return this.du(z,b)}else if(typeof b==="number"&&(b&0x3ffffff)===b){x=this.c
if(x==null){y=Object.create(null)
y["<non-identifier-key>"]=y
delete y["<non-identifier-key>"]
this.c=y
x=y}return this.du(x,b)}else return this.a9(b)},
a9:function(a){var z,y,x
z=this.d
if(z==null){z=P.kz()
this.d=z}y=this.bs(a)
x=z[y]
if(x==null)z[y]=[this.ca(a)]
else{if(this.bt(x,a)>=0)return!1
x.push(this.ca(a))}return!0},
A:function(a,b){if(typeof b==="string"&&b!=="__proto__")return this.dz(this.b,b)
else if(typeof b==="number"&&(b&0x3ffffff)===b)return this.dz(this.c,b)
else return this.cu(b)},
cu:function(a){var z,y,x
z=this.d
if(z==null)return!1
y=z[this.bs(a)]
x=this.bt(y,a)
if(x<0)return!1
this.dA(y.splice(x,1)[0])
return!0},
a7:function(a){if(this.a>0){this.f=null
this.e=null
this.d=null
this.c=null
this.b=null
this.a=0
this.r=this.r+1&67108863}},
du:function(a,b){if(a[b]!=null)return!1
a[b]=this.ca(b)
return!0},
dz:function(a,b){var z
if(a==null)return!1
z=a[b]
if(z==null)return!1
this.dA(z)
delete a[b]
return!0},
ca:function(a){var z,y
z=new P.ky(a,null,null)
if(this.e==null){this.f=z
this.e=z}else{y=this.f
z.c=y
y.b=z
this.f=z}++this.a
this.r=this.r+1&67108863
return z},
dA:function(a){var z,y
z=a.gdw()
y=a.gdv()
if(z==null)this.e=y
else z.b=y
if(y==null)this.f=z
else y.sdw(z);--this.a
this.r=this.r+1&67108863},
bs:function(a){return J.a_(a)&0x3ffffff},
bt:function(a,b){var z,y
if(a==null)return-1
z=a.length
for(y=0;y<z;++y)if(J.J(a[y].gcg(),b))return y
return-1},
$isi:1,
$asi:null,
w:{
kz:function(){var z=Object.create(null)
z["<non-identifier-key>"]=z
delete z["<non-identifier-key>"]
return z}}},
ky:{"^":"e;cg:a<,dv:b<,dw:c@"},
bD:{"^":"e;a,b,c,d",
gt:function(){return this.d},
n:function(){var z=this.a
if(this.b!==z.r)throw H.c(new P.a7(z))
else{z=this.c
if(z==null){this.d=null
return!1}else{this.d=z.gcg()
this.c=this.c.gdv()
return!0}}}},
kq:{"^":"jj;$ti"},
aO:{"^":"iO;$ti"},
iO:{"^":"e+W;",$ash:null,$asi:null,$ish:1,$isi:1},
W:{"^":"e;$ti",
gH:function(a){return new H.bT(a,this.gi(a),0,null)},
L:function(a,b){return this.h(a,b)},
J:function(a,b){var z,y
z=this.gi(a)
for(y=0;y<z;++y){b.$1(this.h(a,y))
if(z!==this.gi(a))throw H.c(new P.a7(a))}},
gD:function(a){return this.gi(a)===0},
gT:function(a){return!this.gD(a)},
af:function(a,b){return new H.b6(a,b,[H.H(a,"W",0),null])},
aB:function(a,b){var z,y,x
z=H.p([],[H.H(a,"W",0)])
C.a.si(z,this.gi(a))
for(y=0;y<this.gi(a);++y){x=this.h(a,y)
if(y>=z.length)return H.a(z,y)
z[y]=x}return z},
aL:function(a){return this.aB(a,!0)},
C:function(a,b){var z=this.gi(a)
this.si(a,z+1)
this.l(a,z,b)},
A:function(a,b){var z
for(z=0;z<this.gi(a);++z)if(J.J(this.h(a,z),b)){this.X(a,z,this.gi(a)-1,a,z+1)
this.si(a,this.gi(a)-1)
return!0}return!1},
X:["df",function(a,b,c,d,e){var z,y,x,w,v
P.cO(b,c,this.gi(a),null,null,null)
z=c-b
if(z===0)return
if(H.bH(d,"$ish",[H.H(a,"W",0)],"$ash")){y=e
x=d}else{x=new H.cP(d,e,null,[H.H(d,"W",0)]).aB(0,!1)
y=0}w=J.w(x)
if(y+z>w.gi(x))throw H.c(H.dQ())
if(y<b)for(v=z-1;v>=0;--v)this.l(a,b+v,w.h(x,y+v))
else for(v=0;v<z;++v)this.l(a,b+v,w.h(x,y+v))}],
ag:function(a,b){var z=this.h(a,b)
this.X(a,b,this.gi(a)-1,a,b+1)
this.si(a,this.gi(a)-1)
return z},
j:function(a){return P.bQ(a,"[","]")},
$ish:1,
$ash:null,
$isi:1,
$asi:null},
l7:{"^":"e;",
l:function(a,b,c){throw H.c(new P.u("Cannot modify unmodifiable map"))},
A:function(a,b){throw H.c(new P.u("Cannot modify unmodifiable map"))},
$isI:1},
iE:{"^":"e;",
h:function(a,b){return this.a.h(0,b)},
l:function(a,b,c){this.a.l(0,b,c)},
M:function(a){return this.a.M(a)},
J:function(a,b){this.a.J(0,b)},
gD:function(a){var z=this.a
return z.gD(z)},
gT:function(a){var z=this.a
return z.gT(z)},
gi:function(a){var z=this.a
return z.gi(z)},
A:function(a,b){return this.a.A(0,b)},
j:function(a){return this.a.j(0)},
$isI:1},
eG:{"^":"iE+l7;$ti",$asI:null,$isI:1},
iG:{"^":"f:5;a,b",
$2:function(a,b){var z,y
z=this.a
if(!z.a)this.b.k+=", "
z.a=!1
z=this.b
y=z.k+=H.b(a)
z.k=y+": "
z.k+=H.b(b)}},
iD:{"^":"b5;a,b,c,d,$ti",
gH:function(a){return new P.kA(this,this.c,this.d,this.b,null)},
gD:function(a){return this.b===this.c},
gi:function(a){return(this.c-this.b&this.a.length-1)>>>0},
L:function(a,b){var z,y,x,w
z=(this.c-this.b&this.a.length-1)>>>0
if(typeof b!=="number")return H.l(b)
if(0>b||b>=z)H.B(P.ai(b,this,"index",null,z))
y=this.a
x=y.length
w=(this.b+b&x-1)>>>0
if(w<0||w>=x)return H.a(y,w)
return y[w]},
C:function(a,b){this.a9(b)},
A:function(a,b){var z,y
for(z=this.b;z!==this.c;z=(z+1&this.a.length-1)>>>0){y=this.a
if(z<0||z>=y.length)return H.a(y,z)
if(J.J(y[z],b)){this.cu(z);++this.d
return!0}}return!1},
a7:function(a){var z,y,x,w,v
z=this.b
y=this.c
if(z!==y){for(x=this.a,w=x.length,v=w-1;z!==y;z=(z+1&v)>>>0){if(z<0||z>=w)return H.a(x,z)
x[z]=null}this.c=0
this.b=0;++this.d}},
j:function(a){return P.bQ(this,"{","}")},
eK:function(){var z,y,x,w
z=this.b
if(z===this.c)throw H.c(H.cD());++this.d
y=this.a
x=y.length
if(z>=x)return H.a(y,z)
w=y[z]
y[z]=null
this.b=(z+1&x-1)>>>0
return w},
a9:function(a){var z,y,x
z=this.a
y=this.c
x=z.length
if(y<0||y>=x)return H.a(z,y)
z[y]=a
x=(y+1&x-1)>>>0
this.c=x
if(this.b===x)this.dL();++this.d},
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
dL:function(){var z,y,x,w
z=new Array(this.a.length*2)
z.fixed$length=Array
y=H.p(z,this.$ti)
z=this.a
x=this.b
w=z.length-x
C.a.X(y,0,w,z,x)
C.a.X(y,w,w+this.b,this.a,0)
this.b=0
this.c=this.a.length
this.a=y},
fz:function(a,b){var z=new Array(8)
z.fixed$length=Array
this.a=H.p(z,[b])},
$asi:null,
w:{
cJ:function(a,b){var z=new P.iD(null,0,0,0,[b])
z.fz(a,b)
return z}}},
kA:{"^":"e;a,b,c,d,e",
gt:function(){return this.e},
n:function(){var z,y,x
z=this.a
if(this.c!==z.d)H.B(new P.a7(z))
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
gT:function(a){return this.a!==0},
V:function(a,b){var z
for(z=J.E(b);z.n();)this.C(0,z.gt())},
af:function(a,b){return new H.cw(this,b,[H.F(this,0),null])},
j:function(a){return P.bQ(this,"{","}")},
bN:function(a,b){var z,y
z=new P.bD(this,this.r,null,null)
z.c=this.e
if(!z.n())return""
if(b===""){y=""
do y+=H.b(z.d)
while(z.n())}else{y=H.b(z.d)
for(;z.n();)y=y+b+H.b(z.d)}return y.charCodeAt(0)==0?y:y},
L:function(a,b){var z,y,x
if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(P.ds("index"))
if(b<0)H.B(P.G(b,0,null,"index",null))
for(z=new P.bD(this,this.r,null,null),z.c=this.e,y=0;z.n();){x=z.d
if(b===y)return x;++y}throw H.c(P.ai(b,this,"index",null,y))},
$isi:1,
$asi:null},
jj:{"^":"jk;$ti"}}],["","",,P,{"^":"",
c7:function(a){var z
if(a==null)return
if(typeof a!="object")return a
if(Object.getPrototypeOf(a)!==Array.prototype)return new P.ks(a,Object.create(null),null)
for(z=0;z<a.length;++z)a[z]=P.c7(a[z])
return a},
lj:function(a,b){var z,y,x,w
if(typeof a!=="string")throw H.c(H.L(a))
z=null
try{z=JSON.parse(a)}catch(x){y=H.D(x)
w=String(y)
throw H.c(new P.bP(w,null,null))}w=P.c7(z)
return w},
o3:[function(a){return a.j1()},"$1","lx",2,0,0,9],
ks:{"^":"e;a,b,c",
h:function(a,b){var z,y
z=this.b
if(z==null)return this.c.h(0,b)
else if(typeof b!=="string")return
else{y=z[b]
return typeof y=="undefined"?this.hf(b):y}},
gi:function(a){var z
if(this.b==null){z=this.c
z=z.gi(z)}else z=this.aS().length
return z},
gD:function(a){var z
if(this.b==null){z=this.c
z=z.gi(z)}else z=this.aS().length
return z===0},
gT:function(a){var z
if(this.b==null){z=this.c
z=z.gi(z)}else z=this.aS().length
return z>0},
l:function(a,b,c){var z,y
if(this.b==null)this.c.l(0,b,c)
else if(this.M(b)){z=this.b
z[b]=c
y=this.a
if(y==null?z!=null:y!==z)y[b]=null}else this.e5().l(0,b,c)},
M:function(a){if(this.b==null)return this.c.M(a)
if(typeof a!=="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
A:function(a,b){if(this.b!=null&&!this.M(b))return
return this.e5().A(0,b)},
J:function(a,b){var z,y,x,w
if(this.b==null)return this.c.J(0,b)
z=this.aS()
for(y=0;y<z.length;++y){x=z[y]
w=this.b[x]
if(typeof w=="undefined"){w=P.c7(this.a[x])
this.b[x]=w}b.$2(x,w)
if(z!==this.c)throw H.c(new P.a7(this))}},
j:function(a){return P.cK(this)},
aS:function(){var z=this.c
if(z==null){z=Object.keys(this.a)
this.c=z}return z},
e5:function(){var z,y,x,w,v
if(this.b==null)return this.c
z=P.iC(P.q,null)
y=this.aS()
for(x=0;w=y.length,x<w;++x){v=y[x]
z.l(0,v,this.h(0,v))}if(w===0)y.push(null)
else C.a.si(y,0)
this.b=null
this.a=null
this.c=z
return z},
hf:function(a){var z
if(!Object.prototype.hasOwnProperty.call(this.a,a))return
z=P.c7(this.a[a])
return this.b[a]=z},
$isI:1,
$asI:function(){return[P.q,null]}},
h8:{"^":"e;"},
dC:{"^":"e;"},
cH:{"^":"P;a,b",
j:function(a){if(this.b!=null)return"Converting object to an encodable object failed."
else return"Converting object did not return an encodable object."}},
iw:{"^":"cH;a,b",
j:function(a){return"Cyclic error in JSON stringify"}},
iv:{"^":"h8;a,b",
hV:function(a,b){var z=P.lj(a,this.ghW().a)
return z},
hU:function(a){return this.hV(a,null)},
i5:function(a,b){var z=this.gi6()
z=P.ku(a,z.b,z.a)
return z},
el:function(a){return this.i5(a,null)},
gi6:function(){return C.H},
ghW:function(){return C.G}},
iy:{"^":"dC;ev:a<,b"},
ix:{"^":"dC;a"},
kv:{"^":"e;",
eW:function(a){var z,y,x,w,v,u,t
z=J.w(a)
y=z.gi(a)
if(typeof y!=="number")return H.l(y)
x=this.c
w=0
v=0
for(;v<y;++v){u=z.cH(a,v)
if(u>92)continue
if(u<32){if(v>w)x.k+=z.al(a,w,v)
w=v+1
x.k+=H.a3(92)
switch(u){case 8:x.k+=H.a3(98)
break
case 9:x.k+=H.a3(116)
break
case 10:x.k+=H.a3(110)
break
case 12:x.k+=H.a3(102)
break
case 13:x.k+=H.a3(114)
break
default:x.k+=H.a3(117)
x.k+=H.a3(48)
x.k+=H.a3(48)
t=u>>>4&15
x.k+=H.a3(t<10?48+t:87+t)
t=u&15
x.k+=H.a3(t<10?48+t:87+t)
break}}else if(u===34||u===92){if(v>w)x.k+=z.al(a,w,v)
w=v+1
x.k+=H.a3(92)
x.k+=H.a3(u)}}if(w===0)x.k+=H.b(a)
else if(w<y)x.k+=z.al(a,w,y)},
c8:function(a){var z,y,x,w
for(z=this.a,y=z.length,x=0;x<y;++x){w=z[x]
if(a==null?w==null:a===w)throw H.c(new P.iw(a,null))}z.push(a)},
bU:function(a){var z,y,x,w
if(this.eV(a))return
this.c8(a)
try{z=this.b.$1(a)
if(!this.eV(z))throw H.c(new P.cH(a,null))
x=this.a
if(0>=x.length)return H.a(x,-1)
x.pop()}catch(w){y=H.D(w)
throw H.c(new P.cH(a,y))}},
eV:function(a){var z,y
if(typeof a==="number"){if(!isFinite(a))return!1
this.c.k+=C.d.j(a)
return!0}else if(a===!0){this.c.k+="true"
return!0}else if(a===!1){this.c.k+="false"
return!0}else if(a==null){this.c.k+="null"
return!0}else if(typeof a==="string"){z=this.c
z.k+='"'
this.eW(a)
z.k+='"'
return!0}else{z=J.j(a)
if(!!z.$ish){this.c8(a)
this.iR(a)
z=this.a
if(0>=z.length)return H.a(z,-1)
z.pop()
return!0}else if(!!z.$isI){this.c8(a)
y=this.iS(a)
z=this.a
if(0>=z.length)return H.a(z,-1)
z.pop()
return y}else return!1}},
iR:function(a){var z,y,x
z=this.c
z.k+="["
y=J.w(a)
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
a.J(0,new P.kw(z,x))
if(!z.b)return!1
w=this.c
w.k+="{"
for(v='"',u=0;u<y;u+=2,v=',"'){w.k+=v
this.eW(x[u])
w.k+='":'
t=u+1
if(t>=y)return H.a(x,t)
this.bU(x[t])}w.k+="}"
return!0}},
kw:{"^":"f:5;a,b",
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
kt:{"^":"kv;c,a,b",w:{
ku:function(a,b,c){var z,y,x
z=new P.aF("")
y=new P.kt(z,[],P.lx())
y.bU(a)
x=z.k
return x.charCodeAt(0)==0?x:x}}}}],["","",,P,{"^":"",
bq:function(a){if(typeof a==="number"||typeof a==="boolean"||null==a)return J.C(a)
if(typeof a==="string")return JSON.stringify(a)
return P.hs(a)},
hs:function(a){var z=J.j(a)
if(!!z.$isf)return z.j(a)
return H.bZ(a)},
bO:function(a){return new P.kc(a)},
av:function(a,b,c){var z,y
z=H.p([],[c])
for(y=J.E(a);y.n();)z.push(y.gt())
if(b)return z
z.fixed$length=Array
return z},
fl:function(a,b){var z,y
z=J.cm(a)
y=H.ed(z,null,P.lz())
if(y!=null)return y
y=H.j5(z,P.ly())
if(y!=null)return y
if(b==null)throw H.c(new P.bP(a,null,null))
return b.$1(a)},
ob:[function(a){return},"$1","lz",2,0,20],
oa:[function(a){return},"$1","ly",2,0,21],
cf:function(a){H.m0(H.b(a))},
je:function(a,b,c){return new H.io(a,H.dU(a,!1,!0,!1),null,null)},
iL:{"^":"f:15;a,b",
$2:function(a,b){var z,y,x
z=this.b
y=this.a
z.k+=y.a
x=z.k+=H.b(a.gha())
z.k=x+": "
z.k+=H.b(P.bq(b))
y.a=", "}},
bF:{"^":"e;"},
"+bool":0,
b2:{"^":"e;a,b",
F:function(a,b){if(b==null)return!1
if(!(b instanceof P.b2))return!1
return this.a===b.a&&this.b===b.b},
gI:function(a){var z=this.a
return(z^C.d.cz(z,30))&1073741823},
j:function(a){var z,y,x,w,v,u,t
z=P.hh(H.j4(this))
y=P.bp(H.j2(this))
x=P.bp(H.iZ(this))
w=P.bp(H.j_(this))
v=P.bp(H.j1(this))
u=P.bp(H.j3(this))
t=P.hi(H.j0(this))
if(this.b)return z+"-"+y+"-"+x+" "+w+":"+v+":"+u+"."+t+"Z"
else return z+"-"+y+"-"+x+" "+w+":"+v+":"+u+"."+t},
C:function(a,b){return P.hg(C.d.v(this.a,b.gj0()),this.b)},
giA:function(){return this.a},
dh:function(a,b){var z
if(!(Math.abs(this.a)>864e13))z=!1
else z=!0
if(z)throw H.c(P.aA(this.giA()))},
w:{
hg:function(a,b){var z=new P.b2(a,b)
z.dh(a,b)
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
bp:function(a){if(a>=10)return""+a
return"0"+a}}},
ap:{"^":"bh;"},
"+double":0,
aD:{"^":"e;aT:a<",
v:function(a,b){return new P.aD(this.a+b.gaT())},
U:function(a,b){return new P.aD(this.a-b.gaT())},
G:function(a,b){if(typeof b!=="number")return H.l(b)
return new P.aD(C.d.aA(this.a*b))},
c4:function(a,b){if(b===0)throw H.c(new P.hV())
return new P.aD(C.f.c4(this.a,b))},
aj:function(a,b){return this.a<b.gaT()},
bX:function(a,b){return this.a>b.gaT()},
bV:function(a,b){return C.f.bV(this.a,b.gaT())},
F:function(a,b){if(b==null)return!1
if(!(b instanceof P.aD))return!1
return this.a===b.a},
gI:function(a){return this.a&0x1FFFFFFF},
j:function(a){var z,y,x,w,v
z=new P.ho()
y=this.a
if(y<0)return"-"+new P.aD(0-y).j(0)
x=z.$1(C.f.bE(y,6e7)%60)
w=z.$1(C.f.bE(y,1e6)%60)
v=new P.hn().$1(y%1e6)
return""+C.f.bE(y,36e8)+":"+H.b(x)+":"+H.b(w)+"."+H.b(v)},
e7:function(a){return new P.aD(Math.abs(this.a))}},
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
gak:function(){return H.Z(this.$thrownJsError)}},
e4:{"^":"P;",
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
u=P.bq(this.b)
return w+v+": "+H.b(u)},
w:{
aA:function(a){return new P.as(!1,null,null,a)},
cn:function(a,b,c){return new P.as(!0,a,b,c)},
ds:function(a){return new P.as(!1,null,a,"Must not be null")}}},
ef:{"^":"as;e,f,a,b,c,d",
gcj:function(){return"RangeError"},
gci:function(){var z,y,x
z=this.e
if(z==null){z=this.f
y=z!=null?": Not less than or equal to "+H.b(z):""}else{x=this.f
if(x==null)y=": Not greater than or equal to "+H.b(z)
else if(x>z)y=": Not in range "+H.b(z)+".."+H.b(x)+", inclusive"
else y=x<z?": Valid value range is empty":": Only valid value is "+H.b(z)}return y},
w:{
b9:function(a,b,c){return new P.ef(null,null,!0,a,b,"Value not in range")},
G:function(a,b,c,d,e){return new P.ef(b,c,!0,a,d,"Invalid value")},
cO:function(a,b,c,d,e,f){if(0>a||a>c)throw H.c(P.G(a,0,c,"start",f))
if(a>b||b>c)throw H.c(P.G(b,a,c,"end",f))
return b}}},
hS:{"^":"as;e,i:f>,a,b,c,d",
gcj:function(){return"RangeError"},
gci:function(){if(J.aZ(this.b,0))return": index must not be negative"
var z=this.f
if(z===0)return": no indices are valid"
return": index should be less than "+H.b(z)},
w:{
ai:function(a,b,c,d,e){var z=e!=null?e:J.a0(b)
return new P.hS(b,z,!0,a,c,"Index out of range")}}},
iK:{"^":"P;a,b,c,d,e",
j:function(a){var z,y,x,w,v,u,t,s
z={}
y=new P.aF("")
z.a=""
for(x=this.c,w=x.length,v=0;v<w;++v){u=x[v]
y.k+=z.a
y.k+=H.b(P.bq(u))
z.a=", "}this.d.J(0,new P.iL(z,y))
t=P.bq(this.a)
s=y.j(0)
x="NoSuchMethodError: method not found: '"+H.b(this.b.a)+"'\nReceiver: "+H.b(t)+"\nArguments: ["+s+"]"
return x},
w:{
e0:function(a,b,c,d,e){return new P.iK(a,b,c,d,e)}}},
u:{"^":"P;a",
j:function(a){return"Unsupported operation: "+this.a}},
cS:{"^":"P;a",
j:function(a){var z=this.a
return z!=null?"UnimplementedError: "+H.b(z):"UnimplementedError"}},
a4:{"^":"P;a",
j:function(a){return"Bad state: "+this.a}},
a7:{"^":"P;a",
j:function(a){var z=this.a
if(z==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+H.b(P.bq(z))+"."}},
iP:{"^":"e;",
j:function(a){return"Out of Memory"},
gak:function(){return},
$isP:1},
el:{"^":"e;",
j:function(a){return"Stack Overflow"},
gak:function(){return},
$isP:1},
hf:{"^":"P;a",
j:function(a){var z=this.a
return z==null?"Reading static variable during its initialization":"Reading static variable '"+H.b(z)+"' during its initialization"}},
kc:{"^":"e;a",
j:function(a){var z=this.a
if(z==null)return"Exception"
return"Exception: "+H.b(z)},
$isbN:1},
bP:{"^":"e;a,b,bP:c>",
j:function(a){var z,y,x
z=this.a
y=z!=null&&""!==z?"FormatException: "+H.b(z):"FormatException"
x=this.b
if(typeof x!=="string")return y
if(x.length>78)x=C.e.al(x,0,75)+"..."
return y+"\n"+x},
$isbN:1},
hV:{"^":"e;",
j:function(a){return"IntegerDivisionByZeroException"},
$isbN:1},
ht:{"^":"e;a,dR",
j:function(a){return"Expando:"+H.b(this.a)},
h:function(a,b){var z,y
z=this.dR
if(typeof z!=="string"){if(b==null||typeof b==="boolean"||typeof b==="number"||typeof b==="string")H.B(P.cn(b,"Expandos are not allowed on strings, numbers, booleans or null",null))
return z.get(b)}y=H.cN(b,"expando$values")
return y==null?null:H.cN(y,z)},
l:function(a,b,c){var z,y
z=this.dR
if(typeof z!=="string")z.set(b,c)
else{y=H.cN(b,"expando$values")
if(y==null){y=new P.e()
H.ee(b,"expando$values",y)}H.ee(y,z,c)}}},
y:{"^":"bh;"},
"+int":0,
R:{"^":"e;$ti",
af:function(a,b){return H.bV(this,b,H.H(this,"R",0),null)},
d7:["fi",function(a,b){return new H.cT(this,b,[H.H(this,"R",0)])}],
aB:function(a,b){return P.av(this,!0,H.H(this,"R",0))},
aL:function(a){return this.aB(a,!0)},
gi:function(a){var z,y
z=this.gH(this)
for(y=0;z.n();)++y
return y},
gD:function(a){return!this.gH(this).n()},
gT:function(a){return!this.gD(this)},
gaC:function(a){var z,y
z=this.gH(this)
if(!z.n())throw H.c(H.cD())
y=z.gt()
if(z.n())throw H.c(H.ig())
return y},
L:function(a,b){var z,y,x
if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(P.ds("index"))
if(b<0)H.B(P.G(b,0,null,"index",null))
for(z=this.gH(this),y=0;z.n();){x=z.gt()
if(b===y)return x;++y}throw H.c(P.ai(b,this,"index",null,y))},
j:function(a){return P.ie(this,"(",")")}},
bR:{"^":"e;"},
h:{"^":"e;$ti",$ash:null,$isi:1,$asi:null},
"+List":0,
b7:{"^":"e;",
gI:function(a){return P.e.prototype.gI.call(this,this)},
j:function(a){return"null"}},
"+Null":0,
bh:{"^":"e;"},
"+num":0,
e:{"^":";",
F:function(a,b){return this===b},
gI:function(a){return H.ax(this)},
j:["fm",function(a){return H.bZ(this)}],
cR:function(a,b){throw H.c(P.e0(this,b.geA(),b.geH(),b.geB(),null))},
toString:function(){return this.j(this)}},
by:{"^":"e;"},
q:{"^":"e;"},
"+String":0,
aF:{"^":"e;k@",
gi:function(a){return this.k.length},
gT:function(a){return this.k.length!==0},
j:function(a){var z=this.k
return z.charCodeAt(0)==0?z:z},
w:{
en:function(a,b,c){var z=J.E(b)
if(!z.n())return a
if(c.length===0){do a+=H.b(z.gt())
while(z.n())}else{a+=H.b(z.gt())
for(;z.n();)a=a+c+H.b(z.gt())}return a}}},
bz:{"^":"e;"}}],["","",,W,{"^":"",
m7:function(){return window},
dr:function(a){var z=document.createElement("a")
if(a!=null)z.href=a
return z},
he:function(a){return a.replace(/^-ms-/,"ms-").replace(/-([\da-z])/ig,function(b,c){return c.toUpperCase()})},
hr:function(a,b,c){var z,y
z=document.body
y=(z&&C.n).a0(z,a,b,c)
y.toString
z=new H.cT(new W.a9(y),new W.lv(),[W.t])
return z.gaC(z)},
b3:function(a){var z,y,x,w
z="element tag unavailable"
try{y=J.m(a)
x=y.geN(a)
if(typeof x==="string")z=y.geN(a)}catch(w){H.D(w)}return z},
hT:function(a){var z,y,x
y=document.createElement("input")
z=y
try{J.fQ(z,a)}catch(x){H.D(x)}return z},
aH:function(a,b){a=536870911&a+b
a=536870911&a+((524287&a)<<10)
return a^a>>>6},
eR:function(a){a=536870911&a+((67108863&a)<<3)
a^=a>>>11
return 536870911&a+((16383&a)<<15)},
eZ:function(a){var z
if(a==null)return
if("postMessage" in a){z=W.k1(a)
if(!!J.j(z).$isV)return z
return}else return a},
fa:function(a){var z=$.x
if(z===C.c)return a
return z.hM(a,!0)},
v:{"^":"N;","%":"HTMLBRElement|HTMLContentElement|HTMLDListElement|HTMLDataListElement|HTMLDetailsElement|HTMLDialogElement|HTMLDirectoryElement|HTMLFontElement|HTMLFrameElement|HTMLHRElement|HTMLHeadElement|HTMLHeadingElement|HTMLHtmlElement|HTMLLabelElement|HTMLLegendElement|HTMLMarqueeElement|HTMLModElement|HTMLOptGroupElement|HTMLParagraphElement|HTMLPictureElement|HTMLPreElement|HTMLQuoteElement|HTMLShadowElement|HTMLSpanElement|HTMLTableCaptionElement|HTMLTableCellElement|HTMLTableColElement|HTMLTableDataCellElement|HTMLTableHeaderCellElement|HTMLTitleElement|HTMLTrackElement|HTMLUListElement|HTMLUnknownElement;HTMLElement"},
fV:{"^":"v;O:type},bM:href}",
j:function(a){return String(a)},
$isk:1,
"%":"HTMLAnchorElement"},
ma:{"^":"v;bM:href}",
j:function(a){return String(a)},
$isk:1,
"%":"HTMLAreaElement"},
mb:{"^":"v;bM:href}","%":"HTMLBaseElement"},
cq:{"^":"k;",$iscq:1,"%":"Blob|File"},
cr:{"^":"v;",$iscr:1,$isV:1,$isk:1,"%":"HTMLBodyElement"},
mc:{"^":"v;P:name=,O:type},E:value%","%":"HTMLButtonElement"},
md:{"^":"v;p:height%,m:width%",
eZ:function(a,b,c){return a.getContext(b)},
d9:function(a,b){return this.eZ(a,b,null)},
"%":"HTMLCanvasElement"},
me:{"^":"k;av:fillStyle},aJ:font},f_:globalAlpha},iy:lineJoin},cM:lineWidth},c2:strokeStyle},d2:textAlign},d3:textBaseline}",
aH:function(a){return a.beginPath()},
hP:function(a,b,c,d,e){return a.clearRect(b,c,d,e)},
em:function(a,b,c,d,e){return a.fillRect(b,c,d,e)},
cO:function(a,b){return a.measureText(b)},
a3:function(a){return a.restore()},
a_:function(a){return a.save()},
iU:function(a,b){return a.stroke(b)},
c1:function(a){return a.stroke()},
ec:function(a,b,c,d,e,f,g){return a.bezierCurveTo(b,c,d,e,f,g)},
cG:function(a){return a.closePath()},
B:function(a,b,c){return a.lineTo(b,c)},
be:function(a,b,c){return a.moveTo(b,c)},
R:function(a,b,c,d,e){return a.quadraticCurveTo(b,c,d,e)},
i9:function(a,b,c,d,e){a.fillText(b,c,d)},
cK:function(a,b,c,d){return this.i9(a,b,c,d,null)},
i8:function(a,b){a.fill(b)},
cJ:function(a){return this.i8(a,"nonzero")},
"%":"CanvasRenderingContext2D"},
mf:{"^":"t;i:length=",$isk:1,"%":"CDATASection|CharacterData|Comment|ProcessingInstruction|Text"},
mg:{"^":"hW;i:length=",
da:function(a,b){var z=this.h0(a,b)
return z!=null?z:""},
h0:function(a,b){if(W.he(b) in a)return a.getPropertyValue(b)
else return a.getPropertyValue(P.hj()+b)},
gp:function(a){return a.height},
gm:function(a){return a.width},
"%":"CSS2Properties|CSSStyleDeclaration|MSStyleCSSProperties"},
hW:{"^":"k+hd;"},
hd:{"^":"e;",
gp:function(a){return this.da(a,"height")},
gm:function(a){return this.da(a,"width")}},
hk:{"^":"v;","%":"HTMLDivElement"},
hl:{"^":"t;",$isk:1,"%":";DocumentFragment"},
mh:{"^":"k;",
j:function(a){return String(a)},
"%":"DOMException"},
hm:{"^":"k;",
j:function(a){return"Rectangle ("+H.b(a.left)+", "+H.b(a.top)+") "+H.b(this.gm(a))+" x "+H.b(this.gp(a))},
F:function(a,b){var z
if(b==null)return!1
z=J.j(b)
if(!z.$isay)return!1
return a.left===z.gbc(b)&&a.top===z.gbi(b)&&this.gm(a)===z.gm(b)&&this.gp(a)===z.gp(b)},
gI:function(a){var z,y,x,w
z=a.left
y=a.top
x=this.gm(a)
w=this.gp(a)
return W.eR(W.aH(W.aH(W.aH(W.aH(0,z&0x1FFFFFFF),y&0x1FFFFFFF),x&0x1FFFFFFF),w&0x1FFFFFFF))},
gd5:function(a){return new P.ak(a.left,a.top,[null])},
gcE:function(a){return a.bottom},
gp:function(a){return a.height},
gbc:function(a){return a.left},
gcZ:function(a){return a.right},
gbi:function(a){return a.top},
gm:function(a){return a.width},
gq:function(a){return a.x},
gu:function(a){return a.y},
$isay:1,
$asay:I.Q,
"%":";DOMRectReadOnly"},
mi:{"^":"k;i:length=",
C:function(a,b){return a.add(b)},
A:function(a,b){return a.remove(b)},
"%":"DOMTokenList"},
jY:{"^":"aO;cl:a<,b",
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
gH:function(a){var z=this.aL(this)
return new J.co(z,z.length,0,null)},
X:function(a,b,c,d,e){throw H.c(new P.cS(null))},
A:function(a,b){return!1},
a7:function(a){J.dh(this.a)},
ag:function(a,b){var z,y
z=this.b
if(b>=z.length)return H.a(z,b)
y=z[b]
this.a.removeChild(y)
return y},
$asaO:function(){return[W.N]},
$ash:function(){return[W.N]},
$asi:function(){return[W.N]}},
ae:{"^":"aO;a,$ti",
gi:function(a){return this.a.length},
h:function(a,b){var z=this.a
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]},
l:function(a,b,c){throw H.c(new P.u("Cannot modify list"))},
si:function(a,b){throw H.c(new P.u("Cannot modify list"))},
gcF:function(a){return W.kH(this)},
$ish:1,
$ash:null,
$isi:1,
$asi:null},
N:{"^":"t;hO:className},dS:namespaceURI=,eN:tagName=",
ghK:function(a){return new W.k6(a)},
geh:function(a){return new W.jY(a,a.children)},
gcF:function(a){return new W.k7(a)},
gbP:function(a){return P.jc(C.d.aA(a.offsetLeft),C.d.aA(a.offsetTop),C.d.aA(a.offsetWidth),C.d.aA(a.offsetHeight),null)},
j:function(a){return a.localName},
ay:function(a,b,c,d,e){var z,y
z=this.a0(a,c,d,e)
switch(b.toLowerCase()){case"beforebegin":a.parentNode.insertBefore(z,a)
break
case"afterbegin":y=a.childNodes
a.insertBefore(z,y.length>0?y[0]:null)
break
case"beforeend":a.appendChild(z)
break
case"afterend":a.parentNode.insertBefore(z,a.nextSibling)
break
default:H.B(P.aA("Invalid position "+b))}},
a0:["c3",function(a,b,c,d){var z,y,x,w,v
if(c==null){z=$.dK
if(z==null){z=H.p([],[W.e1])
y=new W.e2(z)
z.push(W.eP(null))
z.push(W.eV())
$.dK=y
d=y}else d=z
z=$.dJ
if(z==null){z=new W.eW(d)
$.dJ=z
c=z}else{z.a=d
c=z}}if($.at==null){z=document
y=z.implementation.createHTMLDocument("")
$.at=y
$.cx=y.createRange()
y=$.at
y.toString
x=y.createElement("base")
J.fP(x,z.baseURI)
$.at.head.appendChild(x)}z=$.at
if(z.body==null){z.toString
y=z.createElement("body")
z.body=y}z=$.at
if(!!this.$iscr)w=z.body
else{y=a.tagName
z.toString
w=z.createElement(y)
$.at.body.appendChild(w)}if("createContextualFragment" in window.Range.prototype&&!C.a.K(C.J,a.tagName)){$.cx.selectNodeContents(w)
v=$.cx.createContextualFragment(b)}else{w.innerHTML=b
v=$.at.createDocumentFragment()
for(;z=w.firstChild,z!=null;)v.appendChild(z)}z=$.at.body
if(w==null?z!=null:w!==z)J.bl(w)
c.dc(v)
document.adoptNode(v)
return v},function(a,b,c){return this.a0(a,b,c,null)},"hT",null,null,"gj_",2,5,null,1,1],
sew:function(a,b){this.ac(a,b)},
c_:function(a,b,c,d){a.textContent=null
a.appendChild(this.a0(a,b,c,d))},
ac:function(a,b){return this.c_(a,b,null,null)},
en:function(a){return a.focus()},
d8:function(a){return a.getBoundingClientRect()},
gbQ:function(a){return new W.am(a,"change",!1,[W.ab])},
gcS:function(a){return new W.am(a,"input",!1,[W.ab])},
geC:function(a){return new W.am(a,"mousedown",!1,[W.T])},
geD:function(a){return new W.am(a,"mousemove",!1,[W.T])},
geE:function(a){return new W.am(a,"mouseup",!1,[W.T])},
$isN:1,
$ist:1,
$ise:1,
$isk:1,
$isV:1,
"%":";Element"},
lv:{"^":"f:0;",
$1:function(a){return!!J.j(a).$isN}},
mj:{"^":"v;p:height%,P:name=,O:type},m:width%","%":"HTMLEmbedElement"},
mk:{"^":"ab;au:error=","%":"ErrorEvent"},
ab:{"^":"k;",
cW:function(a){return a.preventDefault()},
c0:function(a){return a.stopPropagation()},
$isab:1,
"%":"AnimationEvent|AnimationPlayerEvent|ApplicationCacheErrorEvent|AudioProcessingEvent|AutocompleteErrorEvent|BeforeInstallPromptEvent|BeforeUnloadEvent|BlobEvent|ClipboardEvent|CloseEvent|CustomEvent|DeviceLightEvent|DeviceMotionEvent|DeviceOrientationEvent|FontFaceSetLoadEvent|GamepadEvent|GeofencingEvent|HashChangeEvent|IDBVersionChangeEvent|MIDIConnectionEvent|MIDIMessageEvent|MediaEncryptedEvent|MediaKeyMessageEvent|MediaQueryListEvent|MediaStreamEvent|MediaStreamTrackEvent|MessageEvent|OfflineAudioCompletionEvent|PageTransitionEvent|PopStateEvent|PresentationConnectionAvailableEvent|PresentationConnectionCloseEvent|ProgressEvent|PromiseRejectionEvent|RTCDTMFToneChangeEvent|RTCDataChannelEvent|RTCIceCandidateEvent|RTCPeerConnectionIceEvent|RelatedEvent|ResourceProgressEvent|SecurityPolicyViolationEvent|ServiceWorkerMessageEvent|SpeechRecognitionEvent|SpeechSynthesisEvent|StorageEvent|TrackEvent|TransitionEvent|USBConnectionEvent|WebGLContextEvent|WebKitTransitionEvent;Event|InputEvent"},
V:{"^":"k;",
e8:function(a,b,c,d){if(c!=null)this.fJ(a,b,c,!1)},
eJ:function(a,b,c,d){if(c!=null)this.hl(a,b,c,!1)},
fJ:function(a,b,c,d){return a.addEventListener(b,H.aW(c,1),!1)},
hl:function(a,b,c,d){return a.removeEventListener(b,H.aW(c,1),!1)},
$isV:1,
"%":"MessagePort;EventTarget"},
hM:{"^":"ab;","%":"ExtendableMessageEvent|FetchEvent|InstallEvent|PushEvent|ServicePortConnectEvent|SyncEvent;ExtendableEvent"},
mD:{"^":"v;P:name=","%":"HTMLFieldSetElement"},
mG:{"^":"v;cC:action=,i:length=,P:name=","%":"HTMLFormElement"},
mH:{"^":"i1;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.ai(b,a,null,null,null))
return a[b]},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
L:function(a,b){if(b>>>0!==b||b>=a.length)return H.a(a,b)
return a[b]},
$ish:1,
$ash:function(){return[W.t]},
$isi:1,
$asi:function(){return[W.t]},
$isY:1,
$asY:function(){return[W.t]},
$isS:1,
$asS:function(){return[W.t]},
"%":"HTMLCollection|HTMLFormControlsCollection|HTMLOptionsCollection"},
hX:{"^":"k+W;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
i1:{"^":"hX+bs;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
mI:{"^":"v;p:height%,P:name=,m:width%","%":"HTMLIFrameElement"},
cC:{"^":"k;p:height=,m:width=",$iscC:1,"%":"ImageData"},
mJ:{"^":"v;p:height%,m:width%","%":"HTMLImageElement"},
mL:{"^":"v;p:height%,P:name=,fd:step},O:type},E:value%,m:width%",$isN:1,$isk:1,$isV:1,$ist:1,"%":"HTMLInputElement"},
mS:{"^":"v;P:name=","%":"HTMLKeygenElement"},
mT:{"^":"v;E:value%","%":"HTMLLIElement"},
mV:{"^":"v;bM:href},O:type}","%":"HTMLLinkElement"},
mW:{"^":"k;",
j:function(a){return String(a)},
"%":"Location"},
mX:{"^":"v;P:name=","%":"HTMLMapElement"},
iH:{"^":"v;au:error=","%":"HTMLAudioElement;HTMLMediaElement"},
n_:{"^":"V;",
as:function(a){return a.clone()},
"%":"MediaStream"},
n0:{"^":"v;O:type}","%":"HTMLMenuElement"},
n1:{"^":"v;O:type}","%":"HTMLMenuItemElement"},
n2:{"^":"v;P:name=","%":"HTMLMetaElement"},
n3:{"^":"v;E:value%","%":"HTMLMeterElement"},
n4:{"^":"iI;",
iT:function(a,b,c){return a.send(b,c)},
bZ:function(a,b){return a.send(b)},
"%":"MIDIOutput"},
iI:{"^":"V;","%":"MIDIInput;MIDIPort"},
T:{"^":"jJ;",
gbP:function(a){var z,y,x
if(!!a.offsetX)return new P.ak(a.offsetX,a.offsetY,[null])
else{if(!J.j(W.eZ(a.target)).$isN)throw H.c(new P.u("offsetX is only supported on elements"))
z=W.eZ(a.target)
y=[null]
x=new P.ak(a.clientX,a.clientY,y).U(0,J.fD(J.fE(z)))
return new P.ak(J.dq(x.a),J.dq(x.b),y)}},
"%":"WheelEvent;DragEvent|MouseEvent"},
nf:{"^":"k;",$isk:1,"%":"Navigator"},
a9:{"^":"aO;a",
gaC:function(a){var z,y
z=this.a
y=z.childNodes.length
if(y===0)throw H.c(new P.a4("No elements"))
if(y>1)throw H.c(new P.a4("More than one element"))
return z.firstChild},
C:function(a,b){this.a.appendChild(b)},
V:function(a,b){var z,y,x,w
z=b.a
y=this.a
if(z!==y)for(x=z.childNodes.length,w=0;w<x;++w)y.appendChild(z.firstChild)
return},
ag:function(a,b){var z,y,x
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
gH:function(a){var z=this.a.childNodes
return new W.dN(z,z.length,-1,null)},
X:function(a,b,c,d,e){throw H.c(new P.u("Cannot setRange on Node list"))},
gi:function(a){return this.a.childNodes.length},
si:function(a,b){throw H.c(new P.u("Cannot set length on immutable List."))},
h:function(a,b){var z=this.a.childNodes
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]},
$asaO:function(){return[W.t]},
$ash:function(){return[W.t]},
$asi:function(){return[W.t]}},
t:{"^":"V;cT:parentNode=,iE:previousSibling=",
giD:function(a){return new W.a9(a)},
a2:function(a){var z=a.parentNode
if(z!=null)z.removeChild(a)},
iL:function(a,b){var z,y
try{z=a.parentNode
J.fs(z,b,a)}catch(y){H.D(y)}return a},
fN:function(a){var z
for(;z=a.firstChild,z!=null;)a.removeChild(z)},
j:function(a){var z=a.nodeValue
return z==null?this.fh(a):z},
b4:function(a,b){return a.cloneNode(b)},
hm:function(a,b,c){return a.replaceChild(b,c)},
$ist:1,
$ise:1,
"%":"Document|HTMLDocument|XMLDocument;Node"},
ng:{"^":"i2;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.ai(b,a,null,null,null))
return a[b]},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
L:function(a,b){if(b>>>0!==b||b>=a.length)return H.a(a,b)
return a[b]},
$ish:1,
$ash:function(){return[W.t]},
$isi:1,
$asi:function(){return[W.t]},
$isY:1,
$asY:function(){return[W.t]},
$isS:1,
$asS:function(){return[W.t]},
"%":"NodeList|RadioNodeList"},
hY:{"^":"k+W;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
i2:{"^":"hY+bs;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
nh:{"^":"hM;cC:action=","%":"NotificationEvent"},
nj:{"^":"v;O:type}","%":"HTMLOListElement"},
nk:{"^":"v;p:height%,P:name=,O:type},m:width%","%":"HTMLObjectElement"},
nl:{"^":"v;E:value%","%":"HTMLOptionElement"},
nm:{"^":"v;P:name=,E:value%","%":"HTMLOutputElement"},
nn:{"^":"v;P:name=,E:value%","%":"HTMLParamElement"},
np:{"^":"T;p:height=,m:width=","%":"PointerEvent"},
nq:{"^":"v;E:value%","%":"HTMLProgressElement"},
nr:{"^":"k;",
d8:function(a){return a.getBoundingClientRect()},
"%":"Range"},
nu:{"^":"v;O:type}","%":"HTMLScriptElement"},
nv:{"^":"v;i:length=,P:name=,E:value%","%":"HTMLSelectElement"},
nw:{"^":"hl;",
b4:function(a,b){return a.cloneNode(b)},
as:function(a){return a.cloneNode()},
"%":"ShadowRoot"},
nx:{"^":"v;P:name=","%":"HTMLSlotElement"},
ny:{"^":"v;O:type}","%":"HTMLSourceElement"},
nz:{"^":"ab;au:error=","%":"SpeechRecognitionError"},
nA:{"^":"v;O:type}","%":"HTMLStyleElement"},
jt:{"^":"v;",
a0:function(a,b,c,d){var z,y
if("createContextualFragment" in window.Range.prototype)return this.c3(a,b,c,d)
z=W.hr("<table>"+H.b(b)+"</table>",c,d)
y=document.createDocumentFragment()
y.toString
new W.a9(y).V(0,J.fB(z))
return y},
"%":"HTMLTableElement"},
nE:{"^":"v;",
a0:function(a,b,c,d){var z,y,x,w
if("createContextualFragment" in window.Range.prototype)return this.c3(a,b,c,d)
z=document
y=z.createDocumentFragment()
z=C.u.a0(z.createElement("table"),b,c,d)
z.toString
z=new W.a9(z)
x=z.gaC(z)
x.toString
z=new W.a9(x)
w=z.gaC(z)
y.toString
w.toString
new W.a9(y).V(0,new W.a9(w))
return y},
"%":"HTMLTableRowElement"},
nF:{"^":"v;",
a0:function(a,b,c,d){var z,y,x
if("createContextualFragment" in window.Range.prototype)return this.c3(a,b,c,d)
z=document
y=z.createDocumentFragment()
z=C.u.a0(z.createElement("table"),b,c,d)
z.toString
z=new W.a9(z)
x=z.gaC(z)
y.toString
x.toString
new W.a9(y).V(0,new W.a9(x))
return y},
"%":"HTMLTableSectionElement"},
er:{"^":"v;",
c_:function(a,b,c,d){var z
a.textContent=null
z=this.a0(a,b,c,d)
a.content.appendChild(z)},
ac:function(a,b){return this.c_(a,b,null,null)},
$iser:1,
"%":"HTMLTemplateElement"},
nG:{"^":"v;P:name=,E:value%","%":"HTMLTextAreaElement"},
nH:{"^":"k;m:width=","%":"TextMetrics"},
jJ:{"^":"ab;","%":"CompositionEvent|FocusEvent|KeyboardEvent|SVGZoomEvent|TextEvent|TouchEvent;UIEvent"},
nM:{"^":"iH;p:height%,m:width%","%":"HTMLVideoElement"},
c2:{"^":"V;",
ghI:function(a){var z,y
z=P.bh
y=new P.an(0,$.x,null,[z])
this.fY(a)
this.hn(a,W.fa(new W.jM(new P.l4(y,[z]))))
return y},
hn:function(a,b){return a.requestAnimationFrame(H.aW(b,1))},
fY:function(a){if(!!(a.requestAnimationFrame&&a.cancelAnimationFrame))return;(function(b){var z=['ms','moz','webkit','o']
for(var y=0;y<z.length&&!b.requestAnimationFrame;++y){b.requestAnimationFrame=b[z[y]+'RequestAnimationFrame']
b.cancelAnimationFrame=b[z[y]+'CancelAnimationFrame']||b[z[y]+'CancelRequestAnimationFrame']}if(b.requestAnimationFrame&&b.cancelAnimationFrame)return
b.requestAnimationFrame=function(c){return window.setTimeout(function(){c(Date.now())},16)}
b.cancelAnimationFrame=function(c){clearTimeout(c)}})(a)},
$isc2:1,
$isk:1,
$isV:1,
"%":"DOMWindow|Window"},
jM:{"^":"f:0;a",
$1:[function(a){var z=this.a.a
if(z.a!==0)H.B(new P.a4("Future already completed"))
z.br(a)},null,null,2,0,null,24,"call"]},
nR:{"^":"t;P:name=,dS:namespaceURI=,E:value}","%":"Attr"},
nS:{"^":"k;cE:bottom=,p:height=,bc:left=,cZ:right=,bi:top=,m:width=",
j:function(a){return"Rectangle ("+H.b(a.left)+", "+H.b(a.top)+") "+H.b(a.width)+" x "+H.b(a.height)},
F:function(a,b){var z,y,x
if(b==null)return!1
z=J.j(b)
if(!z.$isay)return!1
y=a.left
x=z.gbc(b)
if(y==null?x==null:y===x){y=a.top
x=z.gbi(b)
if(y==null?x==null:y===x){y=a.width
x=z.gm(b)
if(y==null?x==null:y===x){y=a.height
z=z.gp(b)
z=y==null?z==null:y===z}else z=!1}else z=!1}else z=!1
return z},
gI:function(a){var z,y,x,w
z=J.a_(a.left)
y=J.a_(a.top)
x=J.a_(a.width)
w=J.a_(a.height)
return W.eR(W.aH(W.aH(W.aH(W.aH(0,z),y),x),w))},
gd5:function(a){return new P.ak(a.left,a.top,[null])},
$isay:1,
$asay:I.Q,
"%":"ClientRect"},
nT:{"^":"t;",$isk:1,"%":"DocumentType"},
nU:{"^":"hm;",
gp:function(a){return a.height},
gm:function(a){return a.width},
gq:function(a){return a.x},
sq:function(a,b){a.x=b},
gu:function(a){return a.y},
su:function(a,b){a.y=b},
"%":"DOMRect"},
nW:{"^":"v;",$isV:1,$isk:1,"%":"HTMLFrameSetElement"},
nZ:{"^":"i3;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.ai(b,a,null,null,null))
return a[b]},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
L:function(a,b){if(b>>>0!==b||b>=a.length)return H.a(a,b)
return a[b]},
$ish:1,
$ash:function(){return[W.t]},
$isi:1,
$asi:function(){return[W.t]},
$isY:1,
$asY:function(){return[W.t]},
$isS:1,
$asS:function(){return[W.t]},
"%":"MozNamedAttrMap|NamedNodeMap"},
hZ:{"^":"k+W;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
i3:{"^":"hZ+bs;",
$ash:function(){return[W.t]},
$asi:function(){return[W.t]},
$ish:1,
$isi:1},
o2:{"^":"V;",$isV:1,$isk:1,"%":"ServiceWorker"},
jT:{"^":"e;cl:a<",
J:function(a,b){var z,y,x,w,v
for(z=this.gab(),y=z.length,x=this.a,w=0;w<z.length;z.length===y||(0,H.A)(z),++w){v=z[w]
b.$2(v,x.getAttribute(v))}},
gab:function(){var z,y,x,w,v,u
z=this.a.attributes
y=H.p([],[P.q])
for(x=z.length,w=0;w<x;++w){if(w>=z.length)return H.a(z,w)
v=z[w]
u=J.m(v)
if(u.gdS(v)==null)y.push(u.gP(v))}return y},
gD:function(a){return this.gab().length===0},
gT:function(a){return this.gab().length!==0},
$isI:1,
$asI:function(){return[P.q,P.q]}},
k6:{"^":"jT;a",
M:function(a){return this.a.hasAttribute(a)},
h:function(a,b){return this.a.getAttribute(b)},
l:function(a,b,c){this.a.setAttribute(b,c)},
A:function(a,b){var z,y
z=this.a
y=z.getAttribute(b)
z.removeAttribute(b)
return y},
gi:function(a){return this.gab().length}},
kG:{"^":"aM;a,b",
W:function(){var z=P.a2(null,null,null,P.q)
C.a.J(this.b,new W.kJ(z))
return z},
bT:function(a){var z,y
z=a.bN(0," ")
for(y=this.a,y=new H.bT(y,y.gi(y),0,null);y.n();)J.fO(y.d,z)},
cP:function(a){C.a.J(this.b,new W.kI(a))},
A:function(a,b){return C.a.ib(this.b,!1,new W.kK(b))},
w:{
kH:function(a){return new W.kG(a,new H.b6(a,new W.lw(),[H.F(a,0),null]).aL(0))}}},
lw:{"^":"f:16;",
$1:[function(a){return J.ck(a)},null,null,2,0,null,0,"call"]},
kJ:{"^":"f:7;a",
$1:function(a){return this.a.V(0,a.W())}},
kI:{"^":"f:7;a",
$1:function(a){return a.cP(this.a)}},
kK:{"^":"f:17;a",
$2:function(a,b){return J.fI(b,this.a)===!0||a===!0}},
k7:{"^":"aM;cl:a<",
W:function(){var z,y,x,w,v
z=P.a2(null,null,null,P.q)
for(y=this.a.className.split(" "),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=J.cm(y[w])
if(v.length!==0)z.C(0,v)}return z},
bT:function(a){this.a.className=a.bN(0," ")},
gi:function(a){return this.a.classList.length},
gD:function(a){return this.a.classList.length===0},
gT:function(a){return this.a.classList.length!==0},
K:function(a,b){return typeof b==="string"&&this.a.classList.contains(b)},
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
eL:{"^":"ad;a,b,c,$ti",
a1:function(a,b,c,d){return W.K(this.a,this.b,a,!1,H.F(this,0))},
bd:function(a,b,c){return this.a1(a,null,b,c)}},
am:{"^":"eL;a,b,c,$ti"},
aP:{"^":"ad;a,b,c,$ti",
a1:function(a,b,c,d){var z,y,x,w
z=H.F(this,0)
y=this.$ti
x=new W.kZ(null,new H.a1(0,null,null,null,null,null,0,[[P.ad,z],[P.em,z]]),y)
x.a=new P.c6(null,x.ghQ(x),0,null,null,null,null,y)
for(z=this.a,z=new H.bT(z,z.gi(z),0,null),w=this.c;z.n();)x.C(0,new W.eL(z.d,w,!1,y))
z=x.a
z.toString
return new P.jU(z,[H.F(z,0)]).a1(a,b,c,d)},
az:function(a){return this.a1(a,null,null,null)},
bd:function(a,b,c){return this.a1(a,null,b,c)}},
ka:{"^":"em;a,b,c,d,e,$ti",
aI:function(){if(this.b==null)return
this.e4()
this.b=null
this.d=null
return},
bf:function(a,b){if(this.b==null)return;++this.a
this.e4()},
cU:function(a){return this.bf(a,null)},
gbb:function(){return this.a>0},
cY:function(){if(this.b==null||this.a<=0)return;--this.a
this.e2()},
e2:function(){var z=this.d
if(z!=null&&this.a<=0)J.fu(this.b,this.c,z,!1)},
e4:function(){var z=this.d
if(z!=null)J.fJ(this.b,this.c,z,!1)},
fD:function(a,b,c,d,e){this.e2()},
w:{
K:function(a,b,c,d,e){var z=c==null?null:W.fa(new W.kb(c))
z=new W.ka(0,a,b,z,!1,[e])
z.fD(a,b,c,!1,e)
return z}}},
kb:{"^":"f:0;a",
$1:[function(a){return this.a.$1(a)},null,null,2,0,null,0,"call"]},
kZ:{"^":"e;a,b,$ti",
C:function(a,b){var z,y
z=this.b
if(z.M(b))return
y=this.a
z.l(0,b,b.bd(y.ghD(y),new W.l_(this,b),y.ghF()))},
A:function(a,b){var z=this.b.A(0,b)
if(z!=null)z.aI()},
ei:[function(a){var z,y
for(z=this.b,y=z.gd6(z),y=y.gH(y);y.n();)y.gt().aI()
z.a7(0)
this.a.ei(0)},"$0","ghQ",0,0,1]},
l_:{"^":"f:2;a,b",
$0:function(){return this.a.A(0,this.b)}},
cX:{"^":"e;eT:a<",
aG:function(a){return $.$get$eQ().K(0,W.b3(a))},
ar:function(a,b,c){var z,y,x
z=W.b3(a)
y=$.$get$cY()
x=y.h(0,H.b(z)+"::"+b)
if(x==null)x=y.h(0,"*::"+b)
if(x==null)return!1
return x.$4(a,b,c,this)},
fG:function(a){var z,y
z=$.$get$cY()
if(z.gD(z)){for(y=0;y<262;++y)z.l(0,C.I[y],W.lE())
for(y=0;y<12;++y)z.l(0,C.k[y],W.lF())}},
w:{
eP:function(a){var z,y
z=W.dr(null)
y=window.location
z=new W.cX(new W.kT(z,y))
z.fG(a)
return z},
nX:[function(a,b,c,d){return!0},"$4","lE",8,0,8,12,7,2,13],
nY:[function(a,b,c,d){var z,y,x,w,v
z=d.geT()
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
return z},"$4","lF",8,0,8,12,7,2,13]}},
bs:{"^":"e;$ti",
gH:function(a){return new W.dN(a,this.gi(a),-1,null)},
C:function(a,b){throw H.c(new P.u("Cannot add to immutable List."))},
ag:function(a,b){throw H.c(new P.u("Cannot remove from immutable List."))},
A:function(a,b){throw H.c(new P.u("Cannot remove from immutable List."))},
X:function(a,b,c,d,e){throw H.c(new P.u("Cannot setRange on immutable List."))},
$ish:1,
$ash:null,
$isi:1,
$asi:null},
e2:{"^":"e;a",
C:function(a,b){this.a.push(b)},
aG:function(a){return C.a.ea(this.a,new W.iN(a))},
ar:function(a,b,c){return C.a.ea(this.a,new W.iM(a,b,c))}},
iN:{"^":"f:0;a",
$1:function(a){return a.aG(this.a)}},
iM:{"^":"f:0;a,b,c",
$1:function(a){return a.ar(this.a,this.b,this.c)}},
kU:{"^":"e;eT:d<",
aG:function(a){return this.a.K(0,W.b3(a))},
ar:["fq",function(a,b,c){var z,y
z=W.b3(a)
y=this.c
if(y.K(0,H.b(z)+"::"+b))return this.d.hH(c)
else if(y.K(0,"*::"+b))return this.d.hH(c)
else{y=this.b
if(y.K(0,H.b(z)+"::"+b))return!0
else if(y.K(0,"*::"+b))return!0
else if(y.K(0,H.b(z)+"::*"))return!0
else if(y.K(0,"*::*"))return!0}return!1}],
fH:function(a,b,c,d){var z,y,x
this.a.V(0,c)
z=b.d7(0,new W.kV())
y=b.d7(0,new W.kW())
this.b.V(0,z)
x=this.c
x.V(0,C.i)
x.V(0,y)}},
kV:{"^":"f:0;",
$1:function(a){return!C.a.K(C.k,a)}},
kW:{"^":"f:0;",
$1:function(a){return C.a.K(C.k,a)}},
l5:{"^":"kU;e,a,b,c,d",
ar:function(a,b,c){if(this.fq(a,b,c))return!0
if(b==="template"&&c==="")return!0
if(J.dj(a).a.getAttribute("template")==="")return this.e.K(0,b)
return!1},
w:{
eV:function(){var z=P.q
z=new W.l5(P.dV(C.j,z),P.a2(null,null,null,z),P.a2(null,null,null,z),P.a2(null,null,null,z),null)
z.fH(null,new H.b6(C.j,new W.l6(),[H.F(C.j,0),null]),["TEMPLATE"],null)
return z}}},
l6:{"^":"f:0;",
$1:[function(a){return"TEMPLATE::"+H.b(a)},null,null,2,0,null,25,"call"]},
l0:{"^":"e;",
aG:function(a){var z=J.j(a)
if(!!z.$iseh)return!1
z=!!z.$isz
if(z&&W.b3(a)==="foreignObject")return!1
if(z)return!0
return!1},
ar:function(a,b,c){if(b==="is"||C.e.fb(b,"on"))return!1
return this.aG(a)}},
dN:{"^":"e;a,b,c,d",
n:function(){var z,y
z=this.c+1
y=this.b
if(z<y){this.d=J.af(this.a,z)
this.c=z
return!0}this.d=null
this.c=y
return!1},
gt:function(){return this.d}},
k0:{"^":"e;a",
e8:function(a,b,c,d){return H.B(new P.u("You can only attach EventListeners to your own window."))},
eJ:function(a,b,c,d){return H.B(new P.u("You can only attach EventListeners to your own window."))},
$isV:1,
$isk:1,
w:{
k1:function(a){if(a===window)return a
else return new W.k0(a)}}},
e1:{"^":"e;"},
kT:{"^":"e;a,b"},
eW:{"^":"e;a",
dc:function(a){new W.l8(this).$2(a,null)},
b_:function(a,b){var z
if(b==null){z=a.parentNode
if(z!=null)z.removeChild(a)}else b.removeChild(a)},
hs:function(a,b){var z,y,x,w,v,u,t,s
z=!0
y=null
x=null
try{y=J.dj(a)
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
try{v=J.C(a)}catch(t){H.D(t)}try{u=W.b3(a)
this.hr(a,b,z,v,u,y,x)}catch(t){if(H.D(t) instanceof P.as)throw t
else{this.b_(a,b)
window
s="Removing corrupted element "+H.b(v)
if(typeof console!="undefined")console.warn(s)}}},
hr:function(a,b,c,d,e,f,g){var z,y,x,w,v
if(c){this.b_(a,b)
window
z="Removing element due to corrupted attributes on <"+d+">"
if(typeof console!="undefined")console.warn(z)
return}if(!this.a.aG(a)){this.b_(a,b)
window
z="Removing disallowed element <"+H.b(e)+"> from "+J.C(b)
if(typeof console!="undefined")console.warn(z)
return}if(g!=null)if(!this.a.ar(a,"is",g)){this.b_(a,b)
window
z="Removing disallowed type extension <"+H.b(e)+' is="'+g+'">'
if(typeof console!="undefined")console.warn(z)
return}z=f.gab()
y=H.p(z.slice(0),[H.F(z,0)])
for(x=f.gab().length-1,z=f.a;x>=0;--x){if(x>=y.length)return H.a(y,x)
w=y[x]
if(!this.a.ar(a,J.fT(w),z.getAttribute(w))){window
v="Removing disallowed attribute <"+H.b(e)+" "+H.b(w)+'="'+H.b(z.getAttribute(w))+'">'
if(typeof console!="undefined")console.warn(v)
z.getAttribute(w)
z.removeAttribute(w)}}if(!!J.j(a).$iser)this.dc(a.content)}},
l8:{"^":"f:18;a",
$2:function(a,b){var z,y,x,w,v,u
x=this.a
switch(a.nodeType){case 1:x.hs(a,b)
break
case 8:case 11:case 3:case 4:break
default:x.b_(a,b)}z=a.lastChild
for(x=a==null;null!=z;){y=null
try{y=J.fC(z)}catch(w){H.D(w)
v=z
if(x){u=J.m(v)
if(u.gcT(v)!=null){u.gcT(v)
u.gcT(v).removeChild(v)}}else a.removeChild(v)
z=null
y=a.lastChild}if(z!=null)this.$2(z,a)
z=y}}}}],["","",,P,{"^":"",
dI:function(){var z=$.dH
if(z==null){z=J.cj(window.navigator.userAgent,"Opera",0)
$.dH=z}return z},
hj:function(){var z,y
z=$.dE
if(z!=null)return z
y=$.dF
if(y==null){y=J.cj(window.navigator.userAgent,"Firefox",0)
$.dF=y}if(y)z="-moz-"
else{y=$.dG
if(y==null){y=P.dI()!==!0&&J.cj(window.navigator.userAgent,"Trident/",0)
$.dG=y}if(y)z="-ms-"
else z=P.dI()===!0?"-o-":"-webkit-"}$.dE=z
return z},
aM:{"^":"e;",
cB:function(a){if($.$get$dD().b.test(H.d5(a)))return a
throw H.c(P.cn(a,"value","Not a valid class token"))},
j:function(a){return this.W().bN(0," ")},
gH:function(a){var z,y
z=this.W()
y=new P.bD(z,z.r,null,null)
y.c=z.e
return y},
af:function(a,b){var z=this.W()
return new H.cw(z,b,[H.F(z,0),null])},
gD:function(a){return this.W().a===0},
gT:function(a){return this.W().a!==0},
gi:function(a){return this.W().a},
K:function(a,b){if(typeof b!=="string")return!1
this.cB(b)
return this.W().K(0,b)},
cN:function(a){return this.K(0,a)?a:null},
C:function(a,b){this.cB(b)
return this.cP(new P.hc(b))},
A:function(a,b){var z,y
this.cB(b)
z=this.W()
y=z.A(0,b)
this.bT(z)
return y},
L:function(a,b){return this.W().L(0,b)},
cP:function(a){var z,y
z=this.W()
y=a.$1(z)
this.bT(z)
return y},
$isi:1,
$asi:function(){return[P.q]}},
hc:{"^":"f:0;a",
$1:function(a){return a.C(0,this.a)}},
hN:{"^":"aO;a,b",
gap:function(){var z,y
z=this.b
y=H.H(z,"W",0)
return new H.bU(new H.cT(z,new P.hO(),[y]),new P.hP(),[y,null])},
l:function(a,b,c){var z=this.gap()
J.fL(z.b.$1(J.b_(z.a,b)),c)},
si:function(a,b){var z=J.a0(this.gap().a)
if(b>=z)return
else if(b<0)throw H.c(P.aA("Invalid list length"))
this.iJ(0,b,z)},
C:function(a,b){this.b.a.appendChild(b)},
X:function(a,b,c,d,e){throw H.c(new P.u("Cannot setRange on filtered list"))},
iJ:function(a,b,c){var z=this.gap()
z=H.jl(z,b,H.H(z,"R",0))
C.a.J(P.av(H.ju(z,c-b,H.H(z,"R",0)),!0,null),new P.hQ())},
a7:function(a){J.dh(this.b.a)},
ag:function(a,b){var z,y
z=this.gap()
y=z.b.$1(J.b_(z.a,b))
J.bl(y)
return y},
A:function(a,b){return!1},
gi:function(a){return J.a0(this.gap().a)},
h:function(a,b){var z=this.gap()
return z.b.$1(J.b_(z.a,b))},
gH:function(a){var z=P.av(this.gap(),!1,W.N)
return new J.co(z,z.length,0,null)},
$asaO:function(){return[W.N]},
$ash:function(){return[W.N]},
$asi:function(){return[W.N]}},
hO:{"^":"f:0;",
$1:function(a){return!!J.j(a).$isN}},
hP:{"^":"f:0;",
$1:[function(a){return H.cc(a,"$isN")},null,null,2,0,null,26,"call"]},
hQ:{"^":"f:0;",
$1:function(a){return J.bl(a)}}}],["","",,P,{"^":"",cI:{"^":"k;",$iscI:1,"%":"IDBKeyRange"}}],["","",,P,{"^":"",
la:[function(a,b,c,d){var z,y,x
if(b===!0){z=[c]
C.a.V(z,d)
d=z}y=P.av(J.dn(d,P.lS()),!0,null)
x=H.iX(a,y)
return P.f0(x)},null,null,8,0,null,27,28,29,30],
d1:function(a,b,c){var z
try{if(Object.isExtensible(a)&&!Object.prototype.hasOwnProperty.call(a,b)){Object.defineProperty(a,b,{value:c})
return!0}}catch(z){H.D(z)}return!1},
f2:function(a,b){if(Object.prototype.hasOwnProperty.call(a,b))return a[b]
return},
f0:[function(a){var z
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
z=J.j(a)
if(!!z.$isbx)return a.a
if(!!z.$iscq||!!z.$isab||!!z.$iscI||!!z.$iscC||!!z.$ist||!!z.$isa8||!!z.$isc2)return a
if(!!z.$isb2)return H.X(a)
if(!!z.$iscB)return P.f1(a,"$dart_jsFunction",new P.lc())
return P.f1(a,"_$dart_jsObject",new P.ld($.$get$d0()))},"$1","lT",2,0,0,14],
f1:function(a,b,c){var z=P.f2(a,b)
if(z==null){z=c.$1(a)
P.d1(a,b,z)}return z},
f_:[function(a){var z,y
if(a==null||typeof a=="string"||typeof a=="number"||typeof a=="boolean")return a
else{if(a instanceof Object){z=J.j(a)
z=!!z.$iscq||!!z.$isab||!!z.$iscI||!!z.$iscC||!!z.$ist||!!z.$isa8||!!z.$isc2}else z=!1
if(z)return a
else if(a instanceof Date){z=0+a.getTime()
y=new P.b2(z,!1)
y.dh(z,!1)
return y}else if(a.constructor===$.$get$d0())return a.o
else return P.f9(a)}},"$1","lS",2,0,22,14],
f9:function(a){if(typeof a=="function")return P.d2(a,$.$get$bM(),new P.lm())
if(a instanceof Array)return P.d2(a,$.$get$cW(),new P.ln())
return P.d2(a,$.$get$cW(),new P.lo())},
d2:function(a,b,c){var z=P.f2(a,b)
if(z==null||!(a instanceof Object)){z=c.$1(a)
P.d1(a,b,z)}return z},
bx:{"^":"e;a",
h:["fk",function(a,b){if(typeof b!=="string"&&typeof b!=="number")throw H.c(P.aA("property is not a String or num"))
return P.f_(this.a[b])}],
l:["de",function(a,b,c){if(typeof b!=="string"&&typeof b!=="number")throw H.c(P.aA("property is not a String or num"))
this.a[b]=P.f0(c)}],
gI:function(a){return 0},
F:function(a,b){if(b==null)return!1
return b instanceof P.bx&&this.a===b.a},
j:function(a){var z,y
try{z=String(this.a)
return z}catch(y){H.D(y)
z=this.fm(this)
return z}},
bH:function(a,b){var z,y
z=this.a
y=b==null?null:P.av(new H.b6(b,P.lT(),[H.F(b,0),null]),!0,null)
return P.f_(z[a].apply(z,y))}},
ir:{"^":"bx;a"},
ip:{"^":"iu;a,$ti",
fM:function(a){var z
if(typeof a==="number"&&Math.floor(a)===a)z=a<0||a>=this.gi(this)
else z=!1
if(z)throw H.c(P.G(a,0,this.gi(this),null,null))},
h:function(a,b){var z
if(typeof b==="number"&&b===C.d.d4(b)){if(typeof b==="number"&&Math.floor(b)===b)z=b<0||b>=this.gi(this)
else z=!1
if(z)H.B(P.G(b,0,this.gi(this),null,null))}return this.fk(0,b)},
l:function(a,b,c){var z
if(typeof b==="number"&&b===C.d.d4(b)){if(typeof b==="number"&&Math.floor(b)===b)z=b<0||b>=this.gi(this)
else z=!1
if(z)H.B(P.G(b,0,this.gi(this),null,null))}this.de(0,b,c)},
gi:function(a){var z=this.a.length
if(typeof z==="number"&&z>>>0===z)return z
throw H.c(new P.a4("Bad JsArray length"))},
si:function(a,b){this.de(0,"length",b)},
C:function(a,b){this.bH("push",[b])},
ag:function(a,b){this.fM(b)
return J.af(this.bH("splice",[b,1]),0)},
X:function(a,b,c,d,e){var z,y
P.iq(b,c,this.gi(this))
z=c-b
if(z===0)return
y=[b,z]
C.a.V(y,new H.cP(d,e,null,[H.H(d,"W",0)]).iO(0,z))
this.bH("splice",y)},
w:{
iq:function(a,b,c){if(a>c)throw H.c(P.G(a,0,c,null,null))
if(b<a||b>c)throw H.c(P.G(b,a,c,null,null))}}},
iu:{"^":"bx+W;",$ash:null,$asi:null,$ish:1,$isi:1},
lc:{"^":"f:0;",
$1:function(a){var z=function(b,c,d){return function(){return b(c,d,this,Array.prototype.slice.apply(arguments))}}(P.la,a,!1)
P.d1(z,$.$get$bM(),a)
return z}},
ld:{"^":"f:0;a",
$1:function(a){return new this.a(a)}},
lm:{"^":"f:0;",
$1:function(a){return new P.ir(a)}},
ln:{"^":"f:0;",
$1:function(a){return new P.ip(a,[null])}},
lo:{"^":"f:0;",
$1:function(a){return new P.bx(a)}}}],["","",,P,{"^":"",
ba:function(a,b){a=536870911&a+b
a=536870911&a+((524287&a)<<10)
return a^a>>>6},
eS:function(a){a=536870911&a+((67108863&a)<<3)
a^=a>>>11
return 536870911&a+((16383&a)<<15)},
ak:{"^":"e;q:a>,u:b>,$ti",
j:function(a){return"Point("+H.b(this.a)+", "+H.b(this.b)+")"},
F:function(a,b){var z,y
if(b==null)return!1
if(!(b instanceof P.ak))return!1
z=this.a
y=b.a
if(z==null?y==null:z===y){z=this.b
y=b.b
y=z==null?y==null:z===y
z=y}else z=!1
return z},
gI:function(a){var z,y
z=J.a_(this.a)
y=J.a_(this.b)
return P.eS(P.ba(P.ba(0,z),y))},
v:function(a,b){var z,y,x,w
z=this.a
y=J.m(b)
x=y.gq(b)
if(typeof z!=="number")return z.v()
if(typeof x!=="number")return H.l(x)
w=this.b
y=y.gu(b)
if(typeof w!=="number")return w.v()
if(typeof y!=="number")return H.l(y)
return new P.ak(z+x,w+y,this.$ti)},
U:function(a,b){var z,y,x,w
z=this.a
y=J.m(b)
x=y.gq(b)
if(typeof z!=="number")return z.U()
if(typeof x!=="number")return H.l(x)
w=this.b
y=y.gu(b)
if(typeof w!=="number")return w.U()
if(typeof y!=="number")return H.l(y)
return new P.ak(z-x,w-y,this.$ti)},
G:function(a,b){var z,y
z=this.a
if(typeof z!=="number")return z.G()
if(typeof b!=="number")return H.l(b)
y=this.b
if(typeof y!=="number")return y.G()
return new P.ak(z*b,y*b,this.$ti)}},
kO:{"^":"e;$ti",
gcZ:function(a){var z,y
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
F:function(a,b){var z,y,x,w
if(b==null)return!1
z=J.j(b)
if(!z.$isay)return!1
y=this.a
x=z.gbc(b)
if(y==null?x==null:y===x){x=this.b
w=z.gbi(b)
if(x==null?w==null:x===w){w=this.c
if(typeof y!=="number")return y.v()
if(typeof w!=="number")return H.l(w)
if(y+w===z.gcZ(b)){y=this.d
if(typeof x!=="number")return x.v()
if(typeof y!=="number")return H.l(y)
z=x+y===z.gcE(b)}else z=!1}else z=!1}else z=!1
return z},
gI:function(a){var z,y,x,w,v,u
z=this.a
y=J.a_(z)
x=this.b
w=J.a_(x)
v=this.c
if(typeof z!=="number")return z.v()
if(typeof v!=="number")return H.l(v)
u=this.d
if(typeof x!=="number")return x.v()
if(typeof u!=="number")return H.l(u)
return P.eS(P.ba(P.ba(P.ba(P.ba(0,y),w),z+v&0x1FFFFFFF),x+u&0x1FFFFFFF))},
gd5:function(a){return new P.ak(this.a,this.b,this.$ti)}},
ay:{"^":"kO;bc:a>,bi:b>,m:c>,p:d>,$ti",$asay:null,w:{
jc:function(a,b,c,d,e){var z,y
if(typeof c!=="number")return c.aj()
if(c<0)z=-c*0
else z=c
if(typeof d!=="number")return d.aj()
if(d<0)y=-d*0
else y=d
return new P.ay(a,b,z,y,[e])}}}}],["","",,P,{"^":"",m8:{"^":"aN;",$isk:1,"%":"SVGAElement"},m9:{"^":"z;",$isk:1,"%":"SVGAnimateElement|SVGAnimateMotionElement|SVGAnimateTransformElement|SVGAnimationElement|SVGSetElement"},ml:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEBlendElement"},mm:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEColorMatrixElement"},mn:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEComponentTransferElement"},mo:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFECompositeElement"},mp:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEConvolveMatrixElement"},mq:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEDiffuseLightingElement"},mr:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEDisplacementMapElement"},ms:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEFloodElement"},mt:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEGaussianBlurElement"},mu:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEImageElement"},mv:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEMergeElement"},mw:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEMorphologyElement"},mx:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFEOffsetElement"},my:{"^":"z;q:x=,u:y=","%":"SVGFEPointLightElement"},mz:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFESpecularLightingElement"},mA:{"^":"z;q:x=,u:y=","%":"SVGFESpotLightElement"},mB:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFETileElement"},mC:{"^":"z;p:height=,N:result=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFETurbulenceElement"},mE:{"^":"z;p:height=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGFilterElement"},mF:{"^":"aN;p:height=,m:width=,q:x=,u:y=","%":"SVGForeignObjectElement"},hR:{"^":"aN;","%":"SVGCircleElement|SVGEllipseElement|SVGLineElement|SVGPathElement|SVGPolygonElement|SVGPolylineElement;SVGGeometryElement"},aN:{"^":"z;",$isk:1,"%":"SVGClipPathElement|SVGDefsElement|SVGGElement|SVGSwitchElement;SVGGraphicsElement"},mK:{"^":"aN;p:height=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGImageElement"},b4:{"^":"k;",$ise:1,"%":"SVGLength"},mU:{"^":"i4;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.ai(b,a,null,null,null))
return a.getItem(b)},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
L:function(a,b){return this.h(a,b)},
$ish:1,
$ash:function(){return[P.b4]},
$isi:1,
$asi:function(){return[P.b4]},
"%":"SVGLengthList"},i_:{"^":"k+W;",
$ash:function(){return[P.b4]},
$asi:function(){return[P.b4]},
$ish:1,
$isi:1},i4:{"^":"i_+bs;",
$ash:function(){return[P.b4]},
$asi:function(){return[P.b4]},
$ish:1,
$isi:1},mY:{"^":"z;",$isk:1,"%":"SVGMarkerElement"},mZ:{"^":"z;p:height=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGMaskElement"},b8:{"^":"k;",$ise:1,"%":"SVGNumber"},ni:{"^":"i5;",
gi:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.ai(b,a,null,null,null))
return a.getItem(b)},
l:function(a,b,c){throw H.c(new P.u("Cannot assign element of immutable List."))},
si:function(a,b){throw H.c(new P.u("Cannot resize immutable List."))},
L:function(a,b){return this.h(a,b)},
$ish:1,
$ash:function(){return[P.b8]},
$isi:1,
$asi:function(){return[P.b8]},
"%":"SVGNumberList"},i0:{"^":"k+W;",
$ash:function(){return[P.b8]},
$asi:function(){return[P.b8]},
$ish:1,
$isi:1},i5:{"^":"i0+bs;",
$ash:function(){return[P.b8]},
$asi:function(){return[P.b8]},
$ish:1,
$isi:1},no:{"^":"z;p:height=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGPatternElement"},ns:{"^":"hR;p:height=,m:width=,q:x=,u:y=","%":"SVGRectElement"},eh:{"^":"z;O:type}",$iseh:1,$isk:1,"%":"SVGScriptElement"},nB:{"^":"z;O:type}","%":"SVGStyleElement"},fW:{"^":"aM;a",
W:function(){var z,y,x,w,v,u
z=this.a.getAttribute("class")
y=P.a2(null,null,null,P.q)
if(z==null)return y
for(x=z.split(" "),w=x.length,v=0;v<x.length;x.length===w||(0,H.A)(x),++v){u=J.cm(x[v])
if(u.length!==0)y.C(0,u)}return y},
bT:function(a){this.a.setAttribute("class",a.bN(0," "))}},z:{"^":"N;",
gcF:function(a){return new P.fW(a)},
geh:function(a){return new P.hN(a,new W.a9(a))},
sew:function(a,b){this.ac(a,b)},
a0:function(a,b,c,d){var z,y,x,w,v,u
z=H.p([],[W.e1])
z.push(W.eP(null))
z.push(W.eV())
z.push(new W.l0())
c=new W.eW(new W.e2(z))
y='<svg version="1.1">'+H.b(b)+"</svg>"
z=document
x=z.body
w=(x&&C.n).hT(x,y,c)
v=z.createDocumentFragment()
w.toString
z=new W.a9(w)
u=z.gaC(z)
for(;z=u.firstChild,z!=null;)v.appendChild(z)
return v},
en:function(a){return a.focus()},
gbQ:function(a){return new W.am(a,"change",!1,[W.ab])},
gcS:function(a){return new W.am(a,"input",!1,[W.ab])},
geC:function(a){return new W.am(a,"mousedown",!1,[W.T])},
geD:function(a){return new W.am(a,"mousemove",!1,[W.T])},
geE:function(a){return new W.am(a,"mouseup",!1,[W.T])},
$isz:1,
$isV:1,
$isk:1,
"%":"SVGComponentTransferFunctionElement|SVGDescElement|SVGDiscardElement|SVGFEDistantLightElement|SVGFEFuncAElement|SVGFEFuncBElement|SVGFEFuncGElement|SVGFEFuncRElement|SVGFEMergeNodeElement|SVGMetadataElement|SVGStopElement|SVGTitleElement;SVGElement"},nC:{"^":"aN;p:height=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGSVGElement"},nD:{"^":"z;",$isk:1,"%":"SVGSymbolElement"},es:{"^":"aN;","%":";SVGTextContentElement"},nI:{"^":"es;",$isk:1,"%":"SVGTextPathElement"},nJ:{"^":"es;q:x=,u:y=","%":"SVGTSpanElement|SVGTextElement|SVGTextPositioningElement"},nL:{"^":"aN;p:height=,m:width=,q:x=,u:y=",$isk:1,"%":"SVGUseElement"},nN:{"^":"z;",$isk:1,"%":"SVGViewElement"},nV:{"^":"z;",$isk:1,"%":"SVGGradientElement|SVGLinearGradientElement|SVGRadialGradientElement"},o_:{"^":"z;",$isk:1,"%":"SVGCursorElement"},o0:{"^":"z;",$isk:1,"%":"SVGFEDropShadowElement"},o1:{"^":"z;",$isk:1,"%":"SVGMPathElement"}}],["","",,P,{"^":""}],["","",,P,{"^":"",nt:{"^":"k;",$isk:1,"%":"WebGL2RenderingContext"}}],["","",,P,{"^":""}],["","",,U,{"^":"",
h5:function(a,b){var z
if($.bo==null){z=new H.a1(0,null,null,null,null,null,0,[P.q,U.cu])
$.bo=z
z.l(0,"NetLogo",new U.iJ("  "))
$.bo.l(0,"plain",new U.iU("  "))}if($.bo.M(a))return $.bo.h(0,a).dI(b)
else return C.h.el(b)},
mN:[function(a,b){var z,y
if($.$get$ao().h(0,a) instanceof U.dy){z=$.$get$ao().h(0,a)
C.a.si(z.a,0)
C.a.si(z.r,0)
C.a.A(z.db.c,z)}y=C.h.hU(b)
if(!!J.j(y).$isI){$.$get$ao().l(0,a,U.h6(a,y))
$.$get$ao().h(0,a).Y()}},"$2","lX",4,0,23,3,32],
mM:[function(a,b){if($.$get$ao().M(a))return U.h5(b,$.$get$ao().h(0,a).bK())
return},"$2","lW",4,0,24,3,23],
mO:[function(a){var z
if($.$get$ao().M(a)){z=$.$get$ao().h(0,a).x
z.l(0,"program",$.$get$ao().h(0,a).bK())
return C.h.el(z)}},"$1","lY",2,0,25,3],
o9:[function(){var z=$.$get$d7()
J.bI(z,"NetTango_InitWorkspace",U.lX())
J.bI(z,"NetTango_ExportCode",U.lW())
J.bI(z,"NetTango_Save",U.lY())},"$0","fk",0,0,1],
de:function(a,b){var z,y
if(a==null)return b
else if(typeof a==="number"&&Math.floor(a)===a)return a
else if(typeof a==="string")try{z=H.ed(a,null,null)
return z}catch(y){if(!!J.j(H.D(y)).$isbN)return b
else throw y}return b},
aq:function(a,b){var z,y
if(a==null)return b
else if(typeof a==="number")return a
else if(typeof a==="string")try{z=P.fl(a,null)
return z}catch(y){if(!!J.j(H.D(y)).$isbN)return b
else throw y}return b},
ch:function(a,b){if(a==null)return b
else if(typeof a==="boolean")return a
else if(typeof a==="string")if(a.toLowerCase()==="true"||a.toLowerCase()==="t")return!0
else if(a.toLowerCase()==="false"||a.toLowerCase()==="f")return!1
return b},
bn:{"^":"e;a,cC:b>,O:c',d,q:e*,u:f*,m:r>,x,Z:y@,bR:z@,ev:Q<,ch,eG:cx<,eI:cy<,db,dx,dy,fr,fx,fy,es:go<,dE:id<,k1,k2,k3,k4,dP:r1<,e6:r2<",
gp:function(a){return this.r1?$.$get$o():this.x},
gb8:function(){return 0},
gaK:function(){return 0},
gb7:function(){return this.y!=null},
ger:function(){return this.z!=null},
gbj:function(){return this.f},
ged:function(){var z=this.f
return J.d(z,this.r1?$.$get$o():this.x)},
gb2:function(){var z=this.y
return z!=null?z.gb2():this},
gbO:function(){var z=this.y
if(!(z!=null)){z=this.ch
z=z!=null?z.rx:null}return z},
gey:function(){return this.z==null},
as:function(a){var z=U.fY(this.fy,this.b)
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
for(z=this.cx,y=z.length,x=a.cx,w=0;w<z.length;z.length===y||(0,H.A)(z),++w)x.push(J.di(z[w],a))
for(z=this.cy,y=z.length,x=a.cy,w=0;w<z.length;z.length===y||(0,H.A)(z),++w)x.push(J.di(z[w],a))},
S:function(){var z,y,x,w,v,u
z=P.bS()
z.l(0,"id",this.a)
z.l(0,"action",this.b)
z.l(0,"type",this.c)
z.l(0,"format",this.d)
z.l(0,"start",this.go)
z.l(0,"required",this.fx)
y=this.e
x=$.$get$cp()
z.l(0,"x",J.ci(y,x))
z.l(0,"y",J.ci(this.f,x))
y=this.cx
if(y.length!==0){z.l(0,"params",[])
for(x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=y[w]
J.ar(z.h(0,"params"),v.S())}}y=this.cy
if(y.length!==0){z.l(0,"properties",[])
for(x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){u=y[w]
J.ar(z.h(0,"properties"),u.S())}}return z},
bK:function(){var z=[]
this.a5(z)
return z},
a5:function(a){var z
J.ar(a,this.S())
z=this.y
if(z!=null)z.a5(a)},
bA:function(a,b){var z,y,x,w,v,u,t,s,r
z=$.$get$aa()
y=this.dK(a)
x=$.$get$O()
if(typeof x!=="number")return x.G()
if(typeof y!=="number")return y.v()
this.r=Math.max(H.bG(z),y+x*2)
if(!this.r1&&this.cx.length!==0)for(z=this.cx,y=z.length,w=0,v=0;v<z.length;z.length===y||(0,H.A)(z),++v){u=z[v]
u.bz(a)
t=J.d(J.dl(u),x)
if(typeof t!=="number")return H.l(t)
w+=t}else w=0
if(!this.r1&&this.cy.length!==0)for(z=this.cy,y=z.length,s=0,v=0;v<z.length;z.length===y||(0,H.A)(z),++v)s=Math.max(s,z[v].ho(a))
else s=0
z=J.d(this.e,s)
y=J.d(J.d(this.e,this.r),w)
y=Math.max(H.bG(z),H.bG(y))
b=Math.max(H.bG(b),y)
r=this.gbO()
if(r!=null)b=r.bA(a,b)
z=this.e
if(typeof z!=="number")return H.l(z)
this.r=b-z
return b},
a6:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a6(a+this.gaK(),b)},
b0:["ff",function(){var z,y,x,w,v
z=this.y
if(z!=null){y=this.f
J.fS(z,J.d(y,this.r1?$.$get$o():this.x))
z=this.y
y=this.e
x=z.gev()
w=this.Q
if(typeof x!=="number")return x.U()
v=$.$get$aB()
if(typeof v!=="number")return H.l(v)
J.fR(z,J.d(y,(x-w)*v))
this.y.b0()}}],
dK:function(a){var z,y
z=J.m(a)
z.a_(a)
z.saJ(a,this.fr)
y=z.cO(a,this.b).width
z.a3(a)
return y},
bF:function(a){var z,y,x
if(this.id){z=this.e
y=this.k1
x=this.k3
if(typeof y!=="number")return y.U()
if(typeof x!=="number")return H.l(x)
this.e=J.d(z,y-x)
x=this.f
y=this.k2
z=this.k4
if(typeof y!=="number")return y.U()
if(typeof z!=="number")return H.l(z)
this.f=J.d(x,y-z)
this.k3=this.k1
this.k4=this.k2}return this.id},
ce:function(a){var z,y,x,w,v
z=J.m(a)
z.a_(a)
z.sav(a,this.dx)
z.saJ(a,this.fr)
z.sd2(a,"left")
z.sd3(a,"middle")
y=this.b
x=J.d(this.e,$.$get$O())
w=this.f
v=$.$get$o()
if(typeof v!=="number")return v.ai()
z.cK(a,y,x,J.d(w,v/2))
z.a3(a)},
cf:function(a){var z,y
z=J.m(a)
z.a_(a)
this.cr(a)
z.sc2(a,this.dy)
y=$.$get$U()
if(typeof y!=="number")return H.l(y)
z.scM(a,0.5*y)
z.siy(a,"round")
z.c1(a)
z.a3(a)},
cd:function(a){var z=J.m(a)
z.a_(a)
this.cr(a)
z.sav(a,this.db)
z.cJ(a)
z.sav(a,"rgba(0, 0, 0, "+H.b(Math.min(1,0.075*this.Q)))
z.cJ(a)
z.a3(a)},
fV:function(a){var z,y,x,w
z=J.m(a)
z.a_(a)
z.scM(a,5)
z.sc2(a,"cyan")
z.aH(a)
y=J.d(this.e,$.$get$O())
x=$.$get$aB()
w=this.gb8()
if(typeof x!=="number")return x.G()
z.be(a,J.d(y,x*w),this.f)
this.ct(a,this.z==null&&this.go)
z.c1(a)
z.a3(a)},
fS:function(a){var z,y,x
z=J.m(a)
z.a_(a)
z.scM(a,5)
z.sc2(a,"cyan")
z.aH(a)
y=J.r(J.d(this.e,this.r),$.$get$O())
x=this.f
z.be(a,y,J.d(x,this.r1?$.$get$o():this.x))
this.cs(a,this.y==null&&this.Q===0)
z.c1(a)
z.a3(a)},
fT:function(a){var z,y,x,w,v
z=this.r
for(y=this.cx,x=y.length-1;x>=0;--x){w=$.$get$O()
if(x>=y.length)return H.a(y,x)
v=J.dl(y[x])
if(typeof w!=="number")return w.v()
if(typeof v!=="number")return H.l(v)
if(typeof z!=="number")return z.U()
z-=w+v
if(x>=y.length)return H.a(y,x)
y[x].cI(a,z)}},
fU:function(a){var z,y,x,w
for(z=this.cy,y=0;y<z.length;y=w){x=$.$get$o()
w=y+1
if(typeof x!=="number")return x.G()
z[y].i4(a,x*w)}},
cr:["fe",function(a){var z,y,x,w,v,u
z=J.m(a)
z.aH(a)
y=this.e
x=$.$get$O()
z.be(a,J.d(y,x),this.f)
this.ct(a,this.z==null&&this.go)
y=this.Q===0
w=y&&this.z==null
this.dT(a,w,y&&this.y==null)
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
z.R(a,y,this.f,J.d(y,x),this.f)}else{y=this.z
w=this.e
v=this.f
if(y!=null){y=J.d(v,this.r1?$.$get$o():this.x)
v=this.e
u=this.f
z.R(a,w,y,v,J.r(J.d(u,this.r1?$.$get$o():this.x),x))
z.B(a,this.e,this.f)
z.B(a,J.d(this.e,x),this.f)}else{y=J.d(v,this.r1?$.$get$o():this.x)
v=this.e
u=this.f
z.R(a,w,y,v,J.r(J.d(u,this.r1?$.$get$o():this.x),x))
z.B(a,this.e,J.d(this.f,x))
y=this.e
z.R(a,y,this.f,J.d(y,x),this.f)}}z.cG(a)}],
dT:function(a,b,c){var z,y,x,w,v,u
z=$.$get$O()
y=J.m(a)
y.B(a,J.r(J.d(this.e,this.r),z),this.f)
if(b&&c){y.R(a,J.d(this.e,this.r),this.f,J.d(this.e,this.r),J.d(this.f,z))
x=J.d(this.e,this.r)
w=this.f
y.B(a,x,J.r(J.d(w,this.r1?$.$get$o():this.x),z))
x=J.d(this.e,this.r)
w=this.f
w=J.d(w,this.r1?$.$get$o():this.x)
v=J.r(J.d(this.e,this.r),z)
u=this.f
y.R(a,x,w,v,J.d(u,this.r1?$.$get$o():this.x))}else if(c){y.B(a,J.d(this.e,this.r),this.f)
x=J.d(this.e,this.r)
w=this.f
y.B(a,x,J.r(J.d(w,this.r1?$.$get$o():this.x),z))
x=J.d(this.e,this.r)
w=this.f
w=J.d(w,this.r1?$.$get$o():this.x)
v=J.r(J.d(this.e,this.r),z)
u=this.f
y.R(a,x,w,v,J.d(u,this.r1?$.$get$o():this.x))}else{x=this.e
w=this.r
if(b){y.R(a,J.d(x,w),this.f,J.d(this.e,this.r),J.d(this.f,z))
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
if(typeof z!=="number")return z.G()
y=J.d(y,z*2)
x=$.$get$aB()
w=this.gb8()
if(typeof x!=="number")return x.G()
v=J.d(y,x*w)
if(b){y=J.m(a)
y.B(a,v,this.f)
x=z/2
w=J.bg(v)
y.ec(a,v,J.d(this.f,x),w.v(v,z),J.d(this.f,x),w.v(v,z),this.f)}J.dm(a,J.r(J.d(this.e,this.r),z),this.f)},
cs:function(a,b){var z,y,x,w,v,u,t
z=$.$get$O()
y=this.e
if(typeof z!=="number")return z.G()
x=J.d(y,z*2)
if(!this.r1){y=$.$get$aB()
w=this.gaK()
if(typeof y!=="number")return y.G()
x=J.d(x,y*w)}if(b){y=J.bg(x)
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
u.ec(a,y,v,x,w,x,J.d(t,this.r1?$.$get$o():this.x))}y=J.r(x,z)
w=this.f
J.dm(a,y,J.d(w,this.r1?$.$get$o():this.x))},
bI:function(a){var z,y,x,w,v,u
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
ah:function(a){var z,y,x
this.id=!0
z=a.c
this.k1=z
y=a.d
this.k2=y
this.k3=z
this.k4=y
z=this.z
if(z!=null){z.sZ(null)
this.z=null}for(z=this.fy,x=this;x!=null;){z.hk(x)
z.aO(x)
x=x.gbO()}return this},
bm:function(a){var z
this.id=!1
this.r1=!1
this.r2=!1
z=this.fy
z.hC(this)
z.e0(this)
z.bg()},
bk:function(a){this.k1=a.c
this.k2=a.d},
bl:function(a){},
bo:function(a,b){var z=$.ag
$.ag=z+1
this.a=z
this.r=$.$get$aa()
this.x=$.$get$o()},
w:{
fY:function(a,b){var z,y,x
z=[U.aj]
y=H.p([],z)
z=H.p([],z)
x=$.$get$U()
if(typeof x!=="number")return H.l(x)
x=new U.bn(null,b,null,null,0,0,0,0,null,null,0,null,y,z,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*x)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
x.bo(a,b)
return x},
dt:function(a,b){var z,y,x,w,v,u,t,s,r,q
z=J.w(b)
y=z.h(b,"action")
x=y==null?"":J.C(y)
if(!!J.j(z.h(b,"clauses")).$ish){y=H.p([],[U.aC])
w=[U.aj]
v=H.p([],w)
u=H.p([],w)
t=$.$get$U()
if(typeof t!=="number")return H.l(t)
t=14*t
s=new U.aK(y,null,null,null,x,null,null,0,0,0,0,null,null,0,null,v,u,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(t)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
u=$.ag
$.ag=u+1
s.a=u
u=$.$get$aa()
s.r=u
v=$.$get$o()
s.x=v
t=new U.cy(null,null,null,"end-"+H.b(x),null,null,0,0,0,0,null,null,0,null,H.p([],w),H.p([],w),"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(t)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w=$.ag
$.ag=w+1
t.a=w
t.r=u
t.x=v
t.go=!1
if(typeof v!=="number")return v.ai()
t.x=v/2
t.d=""
s.x1=t
t.ry=s
y.push(t)
s.rx=s.x1}else{y=[U.aj]
if(J.J(z.h(b,"type"),"clause")){w=H.p([],y)
y=H.p([],y)
v=$.$get$U()
if(typeof v!=="number")return H.l(v)
s=new U.aC(null,null,null,x,null,null,0,0,0,0,null,null,0,null,w,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
v=$.ag
$.ag=v+1
s.a=v
s.r=$.$get$aa()
s.x=$.$get$o()
s.go=!1}else{w=H.p([],y)
y=H.p([],y)
v=$.$get$U()
if(typeof v!=="number")return H.l(v)
s=new U.bn(null,x,null,null,0,0,0,0,null,null,0,null,w,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
v=$.ag
$.ag=v+1
s.a=v
s.r=$.$get$aa()
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
s.go=!U.ch(z.h(b,"start"),!1)
s.fx=U.ch(z.h(b,"required"),s.fx)
if(!!J.j(z.h(b,"params")).$ish)for(y=J.E(z.h(b,"params")),w=s.cx;y.n();)w.push(U.cM(s,y.gt()))
if(!!J.j(z.h(b,"properties")).$ish)for(y=J.E(z.h(b,"properties")),w=s.cy;y.n();)w.push(U.cM(s,y.gt()))
y=s.cy.length
w=$.$get$o()
if(typeof w!=="number")return H.l(w)
s.x=(1+y)*w
y=!!s.$isaK
if(y&&!!J.j(z.h(b,"clauses")).$ish)for(w=J.E(z.h(b,"clauses"));w.n();){r=w.gt()
J.bI(r,"type","clause")
q=H.cc(U.dt(a,r),"$isaC")
H.cc(s,"$isaK").dj(q)}if(y&&z.h(b,"end")!=null){y=H.cc(s,"$isaK").x1
z=J.af(z.h(b,"end"),"format")
y.d=z==null?null:J.C(z)}return s}}},
dB:{"^":"bn;cQ:rx@",
gbO:function(){var z=this.y
if(z!=null)return z
else{z=this.rx
if(z!=null)return z
else{z=this.ch
if(z!=null)return z.rx
else return}}},
a6:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a6(a+this.gaK(),this)},
hd:function(a){var z,y,x,w,v,u,t
z=$.$get$O()
if(this.rx!=null){y=this.e
x=$.$get$aB()
y=J.d(y,x)
w=this.f
w=J.d(w,this.r1?$.$get$o():this.x)
v=J.d(this.e,x)
u=this.f
t=J.m(a)
t.R(a,y,w,v,J.d(J.d(u,this.r1?$.$get$o():this.x),z))
y=this.y
w=this.e
if(y!=null){t.B(a,J.d(w,x),J.bk(this.rx))
t.B(a,J.d(J.d(this.e,x),z),J.bk(this.rx))}else{t.B(a,J.d(w,x),J.r(J.bk(this.rx),z))
t.R(a,J.d(this.e,x),J.bk(this.rx),J.d(J.d(this.e,x),z),J.bk(this.rx))}}}},
aC:{"^":"dB;hL:ry?,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gb8:function(){return 1},
gaK:function(){return 1},
gey:function(){return!1},
as:function(a){var z,y,x,w,v,u
z=this.fy
y=this.b
x=[U.aj]
w=H.p([],x)
x=H.p([],x)
v=$.$get$U()
if(typeof v!=="number")return H.l(v)
u=new U.aC(null,null,null,y,null,null,0,0,0,0,null,null,0,null,w,x,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,z,!0,!1,null,null,null,null,!1,!0)
u.bo(z,y)
u.go=!1
this.cc(u)
return u},
a5:function(a){var z,y
z=this.S()
z.l(0,"children",[])
J.ar(a,z)
y=this.y
if(y!=null)y.a5(z.h(0,"children"))},
cf:function(a){},
cd:function(a){},
ah:function(a){return this.ry.ah(a)}},
cy:{"^":"aC;ry,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gb8:function(){return 1},
gaK:function(){return 0},
a6:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a6(a,b)},
a5:function(a){J.ar(a,this.S())},
ce:function(a){}},
aK:{"^":"dB;ry,x1,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gb8:function(){return 0},
gaK:function(){return 1},
as:function(a){var z,y,x,w,v,u
z=U.fX(this.fy,this.b)
this.cc(z)
for(y=this.ry,x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=y[w]
u=J.j(v)
if(!u.$iscy)z.dj(u.as(v))}z.x1.d=this.x1.d
return z},
gb2:function(){var z,y
z=this.x1
y=z.y
return y!=null?y.gb2():z},
a5:function(a){var z,y,x,w
z=this.S()
z.l(0,"children",[])
z.l(0,"clauses",[])
J.ar(a,z)
y=this.y
if(y!=null)y.a5(z.h(0,"children"))
for(y=this.ry,x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)y[w].a5(z.h(0,"clauses"))
y=this.x1.y
if(y!=null)y.a5(a)},
a6:function(a,b){var z,y,x
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a6(a+1,this)
for(z=this.ry,y=z.length,x=0;x<z.length;z.length===y||(0,H.A)(z),++x)z[x].a6(a,b)},
b0:function(){var z,y,x,w,v,u,t,s
this.ff()
for(z=this.ry,y=z.length,x=this,w=0;w<z.length;z.length===y||(0,H.A)(z),++w,x=v){v=z[w]
u=J.m(v)
if(x.gb7()){t=x.gZ().gb2()
u.sq(v,this.e)
s=t.f
u.su(v,J.d(s,t.r1?$.$get$o():t.x))}else{u.sq(v,this.e)
s=J.m(x)
u.su(v,J.d(J.d(s.gu(x),s.gp(x)),$.$get$o()))}v.b0()}},
dj:function(a){var z,y,x,w
a.shL(this)
z=this.ry
C.a.A(z,this.x1)
z.push(a)
z.push(this.x1)
for(y=0;x=z.length,y<x-1;y=w){w=y+1
z[y].scQ(z[w])}if(0>=x)return H.a(z,0)
this.rx=z[0]},
cr:function(a){var z,y,x,w,v,u,t,s,r,q
if(this.r1){this.fe(a)
return}z=$.$get$O()
y=J.m(a)
y.aH(a)
y.be(a,J.d(this.e,z),this.f)
x=this.z==null&&this.go
for(w=this;w!=null;){if(!w.gb7())v=w.gcQ()!=null||this.Q===0
else v=!1
w.ct(a,x)
w.dT(a,x,v)
w.cs(a,v)
w.hd(a)
x=!w.gb7()
w=w.gcQ()}u=this.x1
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
y.R(a,u,t,s,J.r(J.d(q,r.r1?$.$get$o():r.x),z))}u=this.z
t=this.e
s=this.f
if(u!=null){y.B(a,t,s)
y.B(a,J.d(this.e,z),this.f)}else{y.B(a,t,J.d(s,z))
u=this.e
y.R(a,u,this.f,J.d(u,z),this.f)}y.cG(a)},
ft:function(a,b){var z,y,x,w
z="end-"+H.b(b)
y=[U.aj]
x=H.p([],y)
y=H.p([],y)
w=$.$get$U()
if(typeof w!=="number")return H.l(w)
w=new U.cy(null,null,null,z,null,null,0,0,0,0,null,null,0,null,x,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*w)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w.bo(a,z)
w.go=!1
z=$.$get$o()
if(typeof z!=="number")return z.ai()
w.x=z/2
w.d=""
this.x1=w
w.ry=this
this.ry.push(w)
this.rx=this.x1},
w:{
fX:function(a,b){var z,y,x,w
z=H.p([],[U.aC])
y=[U.aj]
x=H.p([],y)
y=H.p([],y)
w=$.$get$U()
if(typeof w!=="number")return H.l(w)
w=new U.aK(z,null,null,null,b,null,null,0,0,0,0,null,null,0,null,x,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*w)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w.bo(a,b)
w.ft(a,b)
return w}}},
ac:{"^":"e;a,b,O:c',d,e",
bJ:function(a){var z,y
z=this.e
y=z.length
if(y===1){if(this.a.c!==this)a.k+="("
a.k+=H.b(this.b)+" "
if(0>=z.length)return H.a(z,0)
z[0].bJ(a)
if(this.a.c!==this)a.k+=")"}else if(y===2){if(this.a.c!==this)a.k+="("
if(0>=y)return H.a(z,0)
z[0].bJ(a)
a.k+=" "+H.b(this.b)+" "
if(1>=z.length)return H.a(z,1)
z[1].bJ(a)
if(this.a.c!==this)a.k+=")"}else{z=this.b
if(z!=null)a.k+=H.b(z)}},
S:function(){var z,y,x,w,v
z=P.au(["name",this.b,"type",this.c])
y=this.e
if(y.length!==0){z.l(0,"children",[])
for(x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=y[w]
J.ar(z.h(0,"children"),v.S())}}y=this.d
if(y!=null)z.l(0,"format",y)
return z},
aw:function(a){var z,y,x,w,v
z=J.w(a)
y=z.h(a,"name")
this.b=y==null?"":J.C(y)
y=z.h(a,"type")
this.c=y==null?"num":J.C(y)
y=this.e
C.a.si(y,0)
if(!!J.j(z.h(a,"children")).$ish)for(z=J.E(z.h(a,"children")),x=[U.ac];z.n();){w=z.gt()
v=new U.ac(this.a,null,J.af(w,"type"),null,H.p([],x))
y.push(v)
v.aw(w)}},
hN:function(a){var z,y,x,w
if(a==null)return this.e.length!==0
z=this.e
y=J.w(a)
if(z.length!==y.gi(a))return!0
x=0
while(!0){w=y.gi(a)
if(typeof w!=="number")return H.l(w)
if(!(x<w))break
w=y.h(a,x)
if(x>=z.length)return H.a(z,x)
if(!J.J(w,z[x].c))return!0;++x}return!1},
f7:function(a){var z,y,x,w,v,u,t
z=this.e
y=z.length===0
if(this.hN(a)){C.a.si(z,0)
if(a!=null){x=J.w(a)
w=[U.ac]
v=0
while(!0){u=x.gi(a)
if(typeof u!=="number")return H.l(u)
if(!(v<u))break
u=v===0&&y&&J.J(x.h(a,v),this.c)
t=this.a
if(u){u=new U.ac(t,null,x.h(a,v),null,H.p([],w))
u.b=this.b
z.push(u)}else z.push(new U.ac(t,null,x.h(a,v),null,H.p([],w)));++v}}}},
eb:function(a){var z,y
z=document.createElement("div")
C.b.ac(z,H.b(this.b))
z.classList.add("nt-expression-text")
z.classList.add("editable")
y=H.b(this.c)
z.classList.add(y)
W.K(z,"click",new U.hF(this,z),!1,W.T)
this.ek(z,a)
a.appendChild(z)},
ek:function(a,b){var z=W.T
W.K(a,"mouseenter",new U.hG(b),!1,z)
W.K(a,"mouseleave",new U.hH(b),!1,z)},
bG:function(a,b){var z=document.createElement("div")
C.b.ac(z,b?"(":")")
z.classList.add("nt-expression-text")
z.classList.add("parenthesis")
this.ek(z,a)
a.appendChild(z)},
hJ:function(a){var z,y
this.b=J.C(U.aq(this.b,0))
z=W.hT("number")
z.className="nt-number-input"
y=J.m(z)
y.sE(z,this.b)
y.sfd(z,"1")
y=y.gbQ(z)
W.K(y.a,y.b,new U.hE(this,z),!1,H.F(y,0))
a.appendChild(z)},
giu:function(){var z=this.b
if(z!=null)return P.fl(z,new U.hI())!=null
return!1},
bS:function(a){var z,y,x
z=document.createElement("div")
z.className="nt-expression"
if((this.giu()||this.b==null)&&J.J(this.c,"num"))this.hJ(z)
else if(this.b==null){z.classList.add("empty")
C.b.ay(z,"beforeend","<small>&#9660;</small>",null,null)}else{y=this.e
x=y.length
if(x===1){this.bG(z,!0)
this.eb(z)
if(0>=y.length)return H.a(y,0)
y[0].bS(z)
this.bG(z,!1)}else if(x===2){this.bG(z,!0)
if(0>=y.length)return H.a(y,0)
y[0].bS(z)
this.eb(z)
if(1>=y.length)return H.a(y,1)
y[1].bS(z)
this.bG(z,!1)}else C.b.ay(z,"beforeend","<div class='nt-expression-text "+H.b(this.c)+"'>"+H.b(this.b)+"</div>",null,null)}if(this.e.length===0){z.classList.add("editable")
W.K(z,"click",new U.hL(this,z),!1,W.T)}a.appendChild(z)},
eF:function(a){var z,y,x,w
z=document
y=new W.ae(z.querySelectorAll(".nt-pulldown-menu"),[null])
y.J(y,new U.hJ())
x=z.createElement("div")
x.classList.add("nt-pulldown-menu")
this.dl(x,this.a.a.cx)
if(J.fA(this.a.a.ch))C.b.ay(x,"beforeend","<hr>",null,null)
this.dl(x,this.a.a.ch)
C.b.ay(x,"beforeend","<hr>",null,null)
w=W.dr("#")
C.m.ac(w,"Clear")
w.className="clear"
x.appendChild(w)
W.K(w,"click",new U.hK(this,x),!1,W.T)
a.appendChild(x)},
dl:function(a,b){var z,y,x,w,v
for(z=J.E(b),y=W.T;z.n();){x=z.gt()
w=J.w(x)
if(J.J(w.h(x,"type"),this.c)){v=document.createElement("a")
v.href="#"
C.m.ac(v,H.b(w.h(x,"name")))
a.appendChild(v)
W.K(v,"click",new U.hD(this,a,x),!1,y)}}}},
hF:{"^":"f:0;a,b",
$1:function(a){this.a.eF(this.b)
J.bm(a)}},
hG:{"^":"f:0;a",
$1:function(a){this.a.classList.add("highlight")}},
hH:{"^":"f:0;a",
$1:function(a){this.a.classList.remove("highlight")}},
hE:{"^":"f:0;a,b",
$1:function(a){var z,y,x,w
z=this.a
y=this.b
x=J.m(y)
w=x.gE(y)
z.b=w
if(w===""){z.b="0"
x.sE(y,"0")}}},
hI:{"^":"f:0;",
$1:function(a){return}},
hL:{"^":"f:0;a,b",
$1:function(a){this.a.eF(this.b)
J.bm(a)}},
hJ:{"^":"f:0;",
$1:function(a){return J.bl(a)}},
hK:{"^":"f:0;a,b",
$1:function(a){var z
C.b.a2(this.b)
z=this.a
z.b=null
C.a.si(z.e,0)
z.a.cX()
z=J.m(a)
z.c0(a)
z.cW(a)}},
hD:{"^":"f:0;a,b,c",
$1:function(a){var z,y,x
C.b.a2(this.b)
z=this.a
y=this.c
x=J.w(y)
z.f7(x.h(y,"arguments"))
z.b=x.h(y,"name")
z.c=x.h(y,"type")
z.d=x.h(y,"format")
z.a.cX()
z=J.m(a)
z.c0(a)
z.cW(a)}},
cz:{"^":"e;a,b,c",
j:function(a){var z,y
z=new P.aF("")
this.c.bJ(z)
y=z.k
return y.charCodeAt(0)==0?y:y},
aw:function(a){var z=J.j(a)
if(!!z.$isI)this.c.aw(a)
else if(a!=null)this.c.b=z.j(a)},
cX:function(){var z=this.b
if(z!=null&&this.c!=null){J.fy(z).a7(0)
this.c.bS(this.b)}}},
cu:{"^":"e;",
aX:function(a,b,c){var z,y
for(z=this.a,y=0;y<b;++y)a.k+=z
a.k+=c+"\n"},
aV:function(a,b,c){var z,y,x,w,v,u,t,s,r,q
z=J.w(b)
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
q=this.dJ(v.h(x,r))
if(typeof q!=="string")H.B(H.L(q))
y=H.dc(y,z,q)}for(r=0;r<s;++r){z="{P"+r+"}"
v=this.dJ(t.h(w,r))
if(typeof v!=="string")H.B(H.L(v))
y=H.dc(y,z,v)}this.aX(a,c,y)},
dJ:function(a){var z=J.w(a)
if(!!J.j(z.h(a,"value")).$isI)return this.aW(z.h(a,"value"))
else{z=z.h(a,"value")
return z==null?"":J.C(z)}},
aW:function(a){var z,y,x,w,v,u
z=J.w(a)
y=z.h(a,"children")
if(y==null||!J.j(y).$ish)y=[]
x=z.h(a,"name")
w=x==null?"":J.C(x)
x=z.h(a,"format")
if(typeof x==="string"){v=z.h(a,"format")
z=J.w(y)
u=0
while(!0){x=z.gi(y)
if(typeof x!=="number")return H.l(x)
if(!(u<x))break
v=J.fK(v,"{"+u+"}",this.aW(z.h(y,u)));++u}return v}else{z=J.w(y)
if(z.gi(y)===1)return"("+H.b(w)+" "+H.b(this.aW(z.h(y,0)))+")"
else if(z.gi(y)===2)return"("+H.b(this.aW(z.h(y,0)))+" "+H.b(w)+" "+H.b(this.aW(z.h(y,1)))+")"
else return w}}},
iU:{"^":"cu;a",
dI:function(a){var z,y
z=new P.aF("")
for(y=J.E(a.h(0,"chains"));y.n();){this.ao(z,y.gt(),0)
z.k+="\n"}y=z.k
return y.charCodeAt(0)==0?y:y},
ao:function(a,b,c){var z,y,x,w,v,u
for(z=J.E(b),y=c+1;z.n();){x=z.gt()
this.aV(a,x,c)
w=J.w(x)
if(!!J.j(w.h(x,"children")).$ish)this.ao(a,w.h(x,"children"),y)
if(!!J.j(w.h(x,"clauses")).$ish)for(w=J.E(w.h(x,"clauses"));w.n();){v=w.gt()
this.aV(a,v,c)
u=J.w(v)
if(!!J.j(u.h(v,"children")).$ish)this.ao(a,u.h(v,"children"),y)}}}},
iJ:{"^":"cu;a",
dI:function(a){var z,y,x,w
z=new P.aF("")
for(y=J.E(a.h(0,"chains"));y.n();){x=y.gt()
w=J.w(x)
if(J.az(w.gi(x),0)&&J.J(J.af(w.h(x,0),"type"),"nlogo:procedure")){this.aV(z,w.ag(x,0),0)
this.ao(z,x,1)
w=z.k+="end\n"
z.k=w+"\n"}}y=z.k
return y.charCodeAt(0)==0?y:y},
ao:function(a,b,c){var z,y,x,w,v,u
for(z=J.E(b),y=c+1;z.n();){x=z.gt()
this.aV(a,x,c)
w=J.w(x)
if(!!J.j(w.h(x,"children")).$ish){this.aX(a,c,"[")
this.ao(a,w.h(x,"children"),y)
this.aX(a,c,"]")}if(!!J.j(w.h(x,"clauses")).$ish)for(w=J.E(w.h(x,"clauses"));w.n();){v=w.gt()
this.aV(a,v,c)
u=J.w(v)
if(!!J.j(u.h(v,"children")).$ish){this.aX(a,c,"[")
this.ao(a,u.h(v,"children"),y)
this.aX(a,c,"]")}}}}},
fZ:{"^":"e;a,b,c,m:d>",
gq:function(a){return J.r(this.a.y,this.d)},
gu:function(a){return 0},
gp:function(a){return this.a.z},
bF:function(a){return!1},
iv:function(a){var z
if(!a.gdP())if(!a.ge6()){z=J.m(a)
z=J.df(J.d(z.gq(a),J.n(z.gm(a),0.75)),J.r(this.a.y,this.d))}else z=!1
else z=!1
return z},
eY:function(a){var z,y,x,w
for(z=this.b,y=z.length,x=0;x<z.length;z.length===y||(0,H.A)(z),++x){w=z[x].a
if(J.J(w.b,a))return w}return},
bz:function(a){var z,y,x,w,v,u,t,s
z=$.$get$aa()
if(typeof z!=="number")return z.G()
this.d=z*1.5
for(z=this.b,y=z.length,x=0;x<z.length;z.length===y||(0,H.A)(z),++x){w=z[x]
v=this.d
u=w.a.dK(a)
t=$.$get$O()
if(typeof t!=="number")return t.G()
if(typeof u!=="number")return u.v()
s=$.$get$bK()
if(typeof s!=="number")return s.G()
this.d=Math.max(v,u+t*2+s*2)}},
cI:function(a,b){var z,y,x,w,v,u,t,s
this.bz(a)
z=J.m(a)
z.a_(a)
z.sav(a,this.c)
y=this.a
z.em(a,J.r(y.y,this.d),0,this.d,y.z)
if(b)z.em(a,J.r(y.y,this.d),0,this.d,y.z)
y=J.r(y.y,this.d)
x=$.$get$bK()
if(typeof x!=="number")return H.l(x)
w=y+x
x=$.$get$o()
if(typeof x!=="number")return x.ai()
v=0+x/2
for(y=this.b,u=y.length,t=0;t<y.length;y.length===u||(0,H.A)(y),++t){s=y[t]
s.b=w
s.c=v
s.i3(a)
v+=x*1.5}z.a3(a)}},
ek:{"^":"e;a,q:b*,u:c*,d,e",
ex:function(){var z,y,x
z=this.e
y=J.a5(z)
x=y.U(z,this.d.bW(this.a.b))
return y.aj(z,0)||J.az(x,0)},
gm:function(a){return this.a.r},
gp:function(a){var z=this.a
return z.r1?$.$get$o():z.x},
i3:function(a){var z,y
z=this.a
J.r(this.e,this.d.bW(z.b))
y=J.m(a)
y.a_(a)
if(!this.ex())y.sf_(a,0.3)
z.e=this.b
z.f=this.c
z.bA(a,$.$get$aa())
z.cd(a)
z.ce(a)
z.cf(a)
y.a3(a)},
bI:function(a){return this.a.bI(a)},
ah:function(a){var z,y,x,w,v
if(this.ex()){z=this.a
y=z.as(0)
y.e=J.r(z.e,5)
y.f=J.r(z.f,5)
y.r2=!0
z=this.d
z.aO(y)
if(!!y.$isaK)for(x=y.ry,w=x.length,v=0;v<x.length;x.length===w||(0,H.A)(x),++v)z.aO(x[v])
return y.ah(a)}return this},
bm:function(a){},
bk:function(a){},
bl:function(a){}},
aj:{"^":"e;a,b,c,d,O:e',f,r,x,y,m:z>,p:Q>,ch",
gE:function(a){var z=this.c
return z==null?"":J.C(z)},
sE:function(a,b){var z=b==null?"":J.C(b)
this.c=z
return z},
gaN:function(a){return H.b(J.C(this.c))+H.b(this.r)},
b4:function(a,b){return U.cM(b,this.S())},
S:["dg",function(){return P.au(["type",this.e,"name",this.f,"unit",this.r,"value",this.gE(this),"default",this.d])}],
bz:function(a){var z,y,x
z=$.$get$O()
if(typeof z!=="number")return z.G()
this.z=z*2
z=J.m(a)
z.a_(a)
z.saJ(a,this.b.fr)
y=this.z
x=z.cO(a,this.gaN(this)).width
if(typeof x!=="number")return H.l(x)
this.z=y+x
z.a3(a)},
ho:function(a){var z,y,x,w,v
this.bz(a)
z=this.z
y=J.m(a)
y.a_(a)
y.saJ(a,this.b.fr)
x=$.$get$aB()
w=y.cO(a,"\u25b8    "+H.b(this.f)).width
if(typeof x!=="number")return x.v()
if(typeof w!=="number")return H.l(w)
v=$.$get$O()
if(typeof v!=="number")return v.G()
y.a3(a)
return z+(x+w+v*2)},
ej:function(a,b,c){var z,y,x,w,v,u,t,s,r
this.x=b
this.y=c
z=this.b
y=J.m(a)
y.saJ(a,z.fr)
y.sd2(a,"center")
y.sd3(a,"middle")
x=J.d(z.e,this.x)
w=J.d(z.f,this.y)
v=$.$get$o()
if(typeof v!=="number")return v.ai()
u=J.r(J.d(w,v/2),this.Q/2)
t=this.z
s=this.Q
y.aH(a)
v=s/2
y.aH(a)
w=J.bg(x)
y.be(a,w.v(x,v),u)
y.B(a,J.r(w.v(x,t),v),u)
r=J.bg(u)
y.R(a,w.v(x,t),u,w.v(x,t),r.v(u,v))
y.B(a,w.v(x,t),J.r(r.v(u,s),v))
y.R(a,w.v(x,t),r.v(u,s),J.r(w.v(x,t),v),r.v(u,s))
y.B(a,w.v(x,v),r.v(u,s))
y.R(a,x,r.v(u,s),x,J.r(r.v(u,s),v))
y.B(a,x,r.v(u,v))
y.R(a,x,u,w.v(x,v),u)
y.cG(a)
y.sav(a,this.ch?z.db:z.dx)
y.cJ(a)
y.sav(a,this.ch?z.dx:z.db)
y.cK(a,this.gaN(this),w.v(x,t/2),r.v(u,s*0.55))},
cI:function(a,b){return this.ej(a,b,0)},
i4:function(a,b){var z,y,x,w,v,u,t,s
z=this.b
y=z.r
x=$.$get$O()
w=this.z
if(typeof x!=="number")return x.v()
if(typeof y!=="number")return y.U()
v=J.d(z.f,b)
u=$.$get$o()
if(typeof u!=="number")return u.ai()
t=J.d(v,u/2)
s=J.d(z.e,$.$get$aB())
u=J.m(a)
u.sav(a,z.dx)
u.saJ(a,z.fr)
u.sd2(a,"left")
u.sd3(a,"middle")
u.cK(a,"\u25b8    "+H.b(this.f),s,t)
this.ej(a,y-(x+w),b)},
bI:function(a){var z,y,x
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
bm:function(a){this.ch=!1
this.bD()
this.b.fy.Y()},
ah:function(a){this.ch=!0
this.b.fy.Y()
return this},
bk:function(a){},
bl:function(a){},
bD:function(){var z,y,x,w,v,u,t
z=document
y=z.createElement("div")
y.className="backdrop"
C.b.ay(y,"beforeend",'      <div class="nt-param-dialog">\n        <div class="nt-param-table">\n          <div class="nt-param-row">'+this.dr()+'</div>\n        </div>\n        <button class="nt-param-confirm">OK</button>\n        <button class="nt-param-cancel">Cancel</button>\n      </div>',null,null)
x=z.querySelector("#"+H.b(this.b.fy.f)).parentElement
if(x==null)return
x.appendChild(y)
w=z.querySelector("#nt-param-label-"+this.a)
v=z.querySelector("#nt-param-"+this.a)
u=[null]
t=[W.T]
new W.aP(new W.ae(z.querySelectorAll(".nt-param-confirm"),u),!1,"click",t).az(new U.iQ(this,y,v))
new W.aP(new W.ae(z.querySelectorAll(".nt-param-cancel"),u),!1,"click",t).az(new U.iR(y))
y.classList.add("show")
if(v!=null){z=J.m(v)
z.en(v)
if(w!=null){u=z.gbQ(v)
W.K(u.a,u.b,new U.iS(w,v),!1,H.F(u,0))
z=z.gcS(v)
W.K(z.a,z.b,new U.iT(w,v),!1,H.F(z,0))}}},
dr:function(){return'      <input class="nt-param-input" id="nt-param-'+this.a+'" type="text" value="'+this.gaN(this)+'">\n      <span class="nt-param-unit">'+H.b(this.r)+"</span>\n    "},
am:function(a,b){var z,y
z=$.e7
$.e7=z+1
this.a=z
z=J.w(b)
y=z.h(b,"type")
this.e=y==null?"num":J.C(y)
y=z.h(b,"name")
this.f=y==null?"":J.C(y)
y=z.h(b,"unit")
this.r=y==null?"":J.C(y)
z=z.h(b,"default")
this.d=z
this.sE(0,z)},
w:{
e6:function(a,b){var z=$.$get$o()
if(typeof z!=="number")return z.G()
z=new U.aj(null,a,null,null,"int","","",0,0,28,z*0.6,!1)
z.am(a,b)
return z},
cM:function(a,b){var z,y,x,w
z=J.w(b)
y=z.h(b,"type")
switch(y==null?"num":J.C(y)){case"int":y=$.$get$o()
if(typeof y!=="number")return y.G()
y=new U.hU(!1,1,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.am(a,b)
y.cx=U.ch(z.h(b,"random"),!1)
y.cy=U.aq(z.h(b,"step"),y.cy)
y.cy=1
return y
case"num":y=$.$get$o()
if(typeof y!=="number")return y.G()
y=new U.cA(null,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.am(a,b)
x=new U.cz(a.fy,null,null)
z=new U.ac(x,null,z.h(b,"type"),null,H.p([],[U.ac]))
x.c=z
y.cx=x
x=y.c
w=J.j(x)
if(!!w.$isI)z.aw(x)
else if(x!=null)z.b=w.j(x)
return y
case"bool":y=$.$get$o()
if(typeof y!=="number")return y.G()
y=new U.cA(null,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.am(a,b)
x=new U.cz(a.fy,null,null)
z=new U.ac(x,null,z.h(b,"type"),null,H.p([],[U.ac]))
x.c=z
y.cx=x
x=y.c
w=J.j(x)
if(!!w.$isI)z.aw(x)
else if(x!=null)z.b=w.j(x)
return y
case"range":y=$.$get$o()
if(typeof y!=="number")return y.G()
y=new U.j6(0,10,!1,1,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.am(a,b)
y.cx=U.ch(z.h(b,"random"),!1)
y.cy=U.aq(z.h(b,"step"),y.cy)
y.db=U.aq(z.h(b,"min"),y.db)
y.dx=U.aq(z.h(b,"max"),y.dx)
return y
case"select":return U.ei(a,b)
case"text":return U.e6(a,b)
default:return U.e6(a,b)}}}},
iQ:{"^":"f:0;a,b,c",
$1:[function(a){var z=this.c
if(z!=null)this.a.sE(0,J.bj(z))
C.b.a2(this.b)
z=this.a.b.fy
z.Y()
z.bg()},null,null,2,0,null,0,"call"]},
iR:{"^":"f:0;a",
$1:[function(a){return C.b.a2(this.a)},null,null,2,0,null,0,"call"]},
iS:{"^":"f:0;a,b",
$1:function(a){J.cl(this.a,J.bj(this.b))}},
iT:{"^":"f:0;a,b",
$1:function(a){J.cl(this.a,J.bj(this.b))}},
e5:{"^":"aj;",
S:["fl",function(){var z=this.dg()
z.l(0,"random",this.cx)
z.l(0,"step",this.cy)
return z}],
gE:function(a){return U.aq(this.c,0)},
sE:function(a,b){var z=U.aq(b,0)
this.c=z
return z},
gaN:function(a){var z=J.fU(H.lZ(this.gE(this)),1)
if(C.e.i7(z,".0"))z=C.e.al(z,0,z.length-2)
return z+H.b(this.r)},
dr:function(){return'      <div class="nt-param-name">'+H.b(this.f)+'</div>\n      <div class="nt-param-value">\n        <input class="nt-param-input" id="nt-param-'+this.a+'" type="number" step="'+H.b(this.cy)+'" value="'+H.b(this.gE(this))+'">\n        <span class="nt-param-unit">'+H.b(this.r)+"</span>\n      </div>\n    "}},
hU:{"^":"e5;cx,cy,a,b,c,d,e,f,r,x,y,z,Q,ch",
gE:function(a){return U.de(this.c,0)},
sE:function(a,b){var z=U.de(b,0)
this.c=z
return z}},
j6:{"^":"e5;db,dx,cx,cy,a,b,c,d,e,f,r,x,y,z,Q,ch",
S:function(){var z=this.fl()
z.l(0,"min",this.db)
z.l(0,"max",this.dx)
return z},
bD:function(){var z,y,x,w,v,u,t,s
z=document
y=z.createElement("div")
y.className="backdrop"
x=z.createElement("div")
x.className="nt-param-dialog"
w=z.createElement("div")
w.className="nt-param-table"
C.b.ay(w,"beforeend",'        <div class="nt-param-row">\n          <div class="nt-param-label">\n            '+H.b(this.f)+':\n            <label id="nt-param-label-'+this.a+'" for="nt-param-'+this.a+'">'+H.b(U.aq(this.c,0))+'</label>\n            <span class="nt-param-unit">'+H.b(this.r)+'</span>\n          </div>\n        </div>\n        <div class="nt-param-row">\n          <div class="nt-param-value">\n            <input class="nt-param-input" id="nt-param-'+this.a+'" type="range" value="'+H.b(U.aq(this.c,0))+'" min="'+H.b(this.db)+'" max="'+H.b(this.dx)+'" step="'+H.b(this.cy)+'">\n          </div>\n        </div>\n      ',null,null)
x.appendChild(w)
v=W.T
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
z=z.gcS(s)
W.K(z.a,z.b,new U.ja(t,s),!1,H.F(z,0))}y.classList.add("show")}},
j7:{"^":"f:0;",
$1:function(a){J.bm(a)}},
j8:{"^":"f:0;a",
$1:function(a){C.b.a2(this.a)}},
j9:{"^":"f:0;a,b,c",
$1:function(a){var z=this.a
z.c=U.aq(J.bj(this.c),0)
C.b.a2(this.b)
z=z.b.fy
z.Y()
z.bg()
J.bm(a)}},
ja:{"^":"f:0;a,b",
$1:function(a){J.cl(this.a,J.bj(this.b))}},
jg:{"^":"aj;cx,a,b,c,d,e,f,r,x,y,z,Q,ch",
gaN:function(a){return H.b(J.C(this.c))+H.b(this.r)+" \u25be"},
b4:function(a,b){return U.ei(b,this.S())},
S:function(){var z=this.dg()
z.l(0,"values",this.cx)
return z},
bD:function(){var z,y,x,w,v,u,t,s,r,q,p
z=document
y=z.createElement("div")
y.className="backdrop"
x=z.createElement("div")
x.className="nt-param-dialog small"
w=z.createElement("div")
w.className="nt-param-table"
for(v=J.E(this.cx),u=W.T;v.n();){t=v.gt()
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
fA:function(a,b){var z=J.w(b)
if(!!J.j(z.h(b,"values")).$ish&&J.az(J.a0(z.h(b,"values")),0)){z=z.h(b,"values")
this.cx=z
this.c=J.af(z,0)}},
w:{
ei:function(a,b){var z=$.$get$o()
if(typeof z!=="number")return z.G()
z=new U.jg([],null,a,null,null,"int","","",0,0,28,z*0.6,!1)
z.am(a,b)
z.fA(a,b)
return z}}},
jh:{"^":"f:0;a,b,c",
$1:function(a){var z,y
z=this.a
y=this.c
z.c=y==null?"":J.C(y)
C.b.a2(this.b)
z=z.b.fy
z.Y()
z.bg()
J.bm(a)}},
ji:{"^":"f:0;a",
$1:function(a){C.b.a2(this.a)}},
cA:{"^":"aj;cx,a,b,c,d,e,f,r,x,y,z,Q,ch",
gaN:function(a){var z=this.cx
return z!=null?z.j(0):""},
gE:function(a){return this.c},
sE:function(a,b){var z
this.c=b
z=this.cx
if(z!=null)z.aw(b)},
b4:function(a,b){return U.hu(b,this.S())},
bD:function(){var z,y,x,w,v,u,t
z=document
y=z.createElement("div")
y.className="backdrop"
C.b.ay(y,"beforeend",'      <div class="nt-param-dialog">\n        <div class="nt-param-table">\n          <div class="nt-param-row">\n            <div class="nt-param-label">'+H.b(this.f)+':</div>\n          </div>\n          <div class="nt-param-row">\n            <div id="nt-expression-'+this.a+'" class="nt-expression-root"></div>\n          </div>\n        </div>\n        <button class="nt-param-confirm">OK</button>\n        <button class="nt-param-cancel">Cancel</button>\n      </div>',null,null)
x=z.querySelector("#"+H.b(this.b.fy.f)).parentElement
if(x==null)return
x.appendChild(y)
w=[null]
v=[W.T]
new W.aP(new W.ae(z.querySelectorAll(".nt-param-confirm"),w),!1,"click",v).az(new U.hy(this,y))
new W.aP(new W.ae(z.querySelectorAll(".nt-param-confirm"),w),!1,"mousedown",v).az(new U.hz())
new W.aP(new W.ae(z.querySelectorAll(".nt-param-confirm"),w),!1,"mouseup",v).az(new U.hA())
new W.aP(new W.ae(z.querySelectorAll(".nt-param-cancel"),w),!1,"click",v).az(new U.hB(y))
y.classList.add("show")
u=this.cx
t="#nt-expression-"+this.a
u.toString
u.b=z.querySelector(t)
u.cX()
new W.aP(new W.ae(z.querySelectorAll(".nt-param-dialog"),w),!1,"click",v).az(new U.hC())},
fw:function(a,b){var z=new U.cz(a.fy,null,null)
z.c=new U.ac(z,null,J.af(b,"type"),null,H.p([],[U.ac]))
this.cx=z
z.aw(this.c)},
w:{
hu:function(a,b){var z=$.$get$o()
if(typeof z!=="number")return z.G()
z=new U.cA(null,null,a,null,null,"int","","",0,0,28,z*0.6,!1)
z.am(a,b)
z.fw(a,b)
return z}}},
hy:{"^":"f:0;a,b",
$1:[function(a){var z
if(document.querySelectorAll(".nt-expression.empty").length>0)return!1
z=this.a
z.c=z.cx.c.S()
C.b.a2(this.b)
z=z.b.fy
z.Y()
z.bg()},null,null,2,0,null,0,"call"]},
hz:{"^":"f:0;",
$1:[function(a){var z=new W.ae(document.querySelectorAll(".nt-expression.empty"),[null])
z.J(z,new U.hx())},null,null,2,0,null,0,"call"]},
hx:{"^":"f:0;",
$1:function(a){return J.ck(a).C(0,"warn")}},
hA:{"^":"f:0;",
$1:[function(a){var z=new W.ae(document.querySelectorAll(".nt-expression.empty"),[null])
z.J(z,new U.hw())},null,null,2,0,null,0,"call"]},
hw:{"^":"f:0;",
$1:function(a){return J.ck(a).A(0,"warn")}},
hB:{"^":"f:0;a",
$1:[function(a){C.b.a2(this.a)},null,null,2,0,null,0,"call"]},
hC:{"^":"f:0;",
$1:[function(a){var z=new W.ae(document.querySelectorAll(".nt-pulldown-menu"),[null])
z.J(z,new U.hv())},null,null,2,0,null,0,"call"]},
hv:{"^":"f:0;",
$1:function(a){return J.bl(a)}},
dy:{"^":"eu;f,r,x,m:y>,p:z>,Q,ch,cx,cy,db,a,b,c,d,e",
eQ:function(){if(this.bF(0))this.Y()
C.M.ghI(window).eO(new U.h7(this))},
bg:function(){var z
this.Y()
try{J.af($.$get$d7(),"NetTango").bH("_relayCallback",[this.f])}catch(z){H.D(z)
P.cf("Unable to relay program changed event to Javascript")}},
bK:function(){var z,y,x,w,v,u,t,s
z=P.au(["chains",[]])
for(y=this.r,x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){v=y[w]
if(v.gey())J.ar(z.h(0,"chains"),v.bK())}for(y=this.Q.b,x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w){u=y[w].a
if(u.fx)if(this.bW(u.b)===0){t=z.h(0,"chains")
s=[]
u.a5(s)
J.ar(t,s)}}return z},
aO:function(a){var z,y,x,w
this.r.push(a)
z=this.a
z.push(a)
for(y=a.geG(),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)z.push(y[w])
for(y=a.geI(),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)z.push(y[w])},
hk:function(a){var z,y,x,w
C.a.A(this.r,a)
z=this.a
C.a.A(z,a)
for(y=a.geG(),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)C.a.A(z,y[w])
for(y=a.geI(),x=y.length,w=0;w<y.length;y.length===x||(0,H.A)(y),++w)C.a.A(z,y[w])
this.Y()},
bW:function(a){var z,y,x,w
for(z=this.r,y=z.length,x=0,w=0;w<z.length;z.length===y||(0,H.A)(z),++w)if(J.J(J.fx(z[w]),a))++x
return x},
e0:function(a){var z,y,x
z=this.dH(a)
if(z!=null){y=z.gZ()
z.sZ(a)
a.z=z
if(y!=null){x=a.gb2()
y.sbR(x)
x.y=y}return!0}z=this.dG(a)
if(z!=null){z.sbR(a)
a.y=z
return!0}return!1},
hC:function(a){var z,y
if(this.Q.iv(a))for(z=this.r,y=this.a;a!=null;){C.a.A(z,a)
C.a.A(y,a)
a=a.gbO()}},
dH:function(a){var z,y,x,w,v,u,t,s,r
if(a.gbR()==null&&a.ges())for(z=this.r,y=z.length,x=J.m(a),w=0;w<z.length;z.length===y||(0,H.A)(z),++w){v=z[w]
u=J.j(v)
if(!u.F(v,a))if(J.aZ(x.gq(a),J.d(u.gq(v),u.gm(v)))&&J.az(J.d(x.gq(a),x.gm(a)),u.gq(v))){t=u.gu(v)
s=J.d(u.gu(v),u.gp(v))
r=J.d(s,$.$get$O())
if(v.gb7()&&J.aZ(a.gbj(),s)&&J.az(a.gbj(),t))return v
else if(!v.gb7()&&J.az(a.gbj(),t)&&J.aZ(a.gbj(),r))return v}}return},
dG:function(a){var z,y,x,w,v,u
if(a.gZ()==null)for(z=this.r,y=z.length,x=J.m(a),w=0;w<z.length;z.length===y||(0,H.A)(z),++w){v=z[w]
u=J.j(v)
if(!u.F(v,a)&&v.gbR()==null&&v.ges())if(J.aZ(x.gq(a),J.d(u.gq(v),u.gm(v)))&&J.az(J.d(x.gq(a),x.gm(a)),u.gq(v)))if(J.aZ(J.ft(J.r(v.gbj(),a.ged())),20))return v}return},
bF:function(a){var z,y,x,w,v,u,t,s,r,q
this.Q.toString
for(z=this.r,y=z.length,x=!1,w=0,v=0;v<z.length;z.length===y||(0,H.A)(z),++v){u=z[v]
if(J.fv(u))x=!0
w=Math.max(H.bG(u.ged()),w)}z=this.z
if(typeof z!=="number")return H.l(z)
if(w>z)if(!x){z=this.y
y=$.$get$U()
z=J.ci(z,y)
t=$.$get$o()
if(typeof t!=="number")return t.G()
if(typeof y!=="number")return H.l(y)
s=C.d.aA(z)
r=C.y.aA((w+t*3)/y)
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
y.sm(q,z)
y.sp(q,this.z)
this.cy=y.d9(q,"2d")
this.Y()}}return x},
Y:function(){var z,y,x,w,v,u,t,s,r
J.fN(this.cy)
J.fw(this.cy,0,0,this.y,this.z)
z=H.p([],[U.bn])
for(y=this.r,x=y.length,w=!1,v=0;v<y.length;y.length===x||(0,H.A)(y),++v){u=y[v]
if(!u.ger()&&!(u instanceof U.aC)){u.a6(0,null)
u.b0()
u.bA(this.cy,$.$get$aa())}if(u.gdE())z.push(u)
t=this.Q
t.toString
if(!u.gdP())if(!u.ge6()){s=J.m(u)
t=J.df(J.d(s.gq(u),J.n(s.gm(u),0.75)),J.r(t.a.y,t.d))}else t=!1
else t=!1
if(t)w=!0}this.Q.cI(this.cy,w)
for(x=y.length,v=0;v<y.length;y.length===x||(0,H.A)(y),++v){u=y[v]
if(u.gdE()){r=this.dH(u)
if(r!=null)r.fS(this.cy)
else{r=this.dG(u)
if(r!=null)r.fV(this.cy)}}u.cd(this.cy)
u.ce(this.cy)
u.fT(this.cy)
u.fU(this.cy)
u.cf(this.cy)}J.fM(this.cy)},
hq:function(a){var z,y,x,w
z=J.w(a)
if(!!J.j(z.h(a,"chains")).$ish)for(z=J.E(z.h(a,"chains"));z.n();){y=z.gt()
x=J.j(y)
if(!!x.$ish)for(x=x.gH(y);x.n();){w=x.gt()
if(!!J.j(w).$isI)this.cv(w)}}},
cv:function(a){var z,y,x,w,v,u,t,s,r
z=J.w(a)
y=this.Q.eY(z.h(a,"action"))
if(y!=null){x=y.as(0)
w=z.h(a,"x")
if(typeof w==="number"){w=z.h(a,"y")
w=typeof w==="number"}else w=!1
if(w){w=z.h(a,"x")
v=$.$get$cp()
x.e=J.n(w,v)
x.f=J.n(z.h(a,"y"),v)}this.aO(x)
if(!!x.$isaK)for(w=x.ry,v=w.length,u=0;u<w.length;w.length===v||(0,H.A)(w),++u)this.aO(w[u])
this.e0(x)
for(w=this.r,v=w.length,u=0;u<w.length;w.length===v||(0,H.A)(w),++u){t=w[u]
if(!t.ger()&&!(t instanceof U.aC)){t.a6(0,null)
t.b0()
t.bA(this.cy,$.$get$aa())}}this.hp(x,z.h(a,"params"),z.h(a,"properties"))
if(!!J.j(z.h(a,"children")).$ish)for(w=J.E(z.h(a,"children"));w.n();){s=w.gt()
if(!!J.j(s).$isI)this.cv(s)}if(!!J.j(z.h(a,"clauses")).$ish)for(z=J.E(z.h(a,"clauses"));z.n();){r=z.gt()
w=J.j(r)
if(!!w.$isI&&!!J.j(w.h(r,"children")).$ish)for(w=J.E(w.h(r,"children"));w.n();)this.cv(w.gt())}}},
hp:function(a,b,c){var z,y,x,w,v,u
z=J.j(b)
if(!!z.$ish)for(z=z.gH(b),y=a.cx,x=0;z.n();){w=z.gt()
v=J.j(w)
if(!!v.$isI&&w.M("value")===!0){if(x>=y.length)return H.a(y,x)
J.dp(y[x],v.h(w,"value"))}++x}z=J.j(c)
if(!!z.$ish)for(z=z.gH(c),y=a.cy,x=0;z.n();){u=z.gt()
v=J.j(u)
if(!!v.$isI&&u.M("value")===!0){if(x>=y.length)return H.a(y,x)
J.dp(y[x],v.h(u,"value"))}++x}},
fu:function(a,b){var z,y,x,w,v,u,t,s,r
z=this.f
y="#"+H.b(z)
x=document.querySelector(y)
if(x==null)throw H.c("No canvas element with ID "+H.b(z)+" found.")
z=J.m(x)
this.cy=z.d9(x,"2d")
y=x.style
w=H.b(z.gm(x))+"px"
y.width=w
y=x.style
w=H.b(z.gp(x))+"px"
y.height=w
y=z.gm(x)
w=$.$get$U()
this.y=J.n(y,w)
this.z=J.n(z.gp(x),w)
z.sm(x,this.y)
z.sp(x,this.z)
if(typeof w!=="number")return H.l(w)
z=this.c
y=new U.bW([1,0,0,0,1,0,0,0,1])
y.a=[1/w,0,0,0,1/w,0,0,0,1]
z.iB(y)
this.d=this.c.is()
y=this.db
y.iG(x)
y.c.push(this)
y=H.p([],[U.ek])
z=$.$get$aa()
w=$.$get$bK()
if(typeof w!=="number")return w.G()
if(typeof z!=="number")return z.v()
this.Q=new U.fZ(this,y,"rgba(0,0,0, 0.2)",z+w*2)
z=this.x
if(!!J.j(z.h(0,"blocks")).$ish)for(y=J.E(z.h(0,"blocks"));y.n();){v=y.gt()
u=U.dt(this,v)
t=U.de(J.af(v,"limit"),-1)
w=this.Q
s=w.b
w=w.a
r=new U.ek(u,null,null,w,t)
u.r1=!0
w.a.push(r)
s.push(r)}if(!!J.j(z.h(0,"variables")).$ish)this.ch=z.h(0,"variables")
if(!!J.j(z.h(0,"expressions")).$ish)this.cx=z.h(0,"expressions")
if(!!J.j(z.h(0,"program")).$isI)this.hq(z.h(0,"program"))
this.Y()
this.eQ()},
w:{
h6:function(a,b){var z,y,x,w,v
z=H.p([],[U.bn])
y=H.p([],[U.eu])
x=P.y
w=U.jH
v=H.p([],[w])
z=new U.dy(a,z,b,null,null,null,[],[],null,new U.jB(!1,null,y,new H.a1(0,null,null,null,null,null,0,[x,U.et])),v,new H.a1(0,null,null,null,null,null,0,[x,w]),new U.bW([1,0,0,0,1,0,0,0,1]),new U.bW([1,0,0,0,1,0,0,0,1]),new P.b2(Date.now(),!1))
z.fu(a,b)
return z}}},
h7:{"^":"f:0;a",
$1:function(a){return this.a.eQ()}},
bW:{"^":"e;a",
is:function(){var z,y,x,w,v,u,t,s,r,q,p,o
z=[1,0,0,0,1,0,0,0,1]
y=new U.bW(z)
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
aM:function(a){var z,y,x,w,v,u,t,s,r
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
z[y].e=new P.b2(Date.now(),!1)
if(y>=z.length)return H.a(z,y)
return new U.et(z[y],x)}else if(y>=z.length)return H.a(z,y)}return},
iG:function(a){var z,y
this.b=a
z=J.m(a)
y=z.geC(a)
W.K(y.a,y.b,new U.jC(this),!1,H.F(y,0))
y=z.geE(a)
W.K(y.a,y.b,new U.jD(this),!1,H.F(y,0))
z=z.geD(a)
W.K(z.a,z.b,new U.jE(this),!1,H.F(z,0))
z=document
W.K(z,"keydown",new U.jF(this),!1,W.mR)
W.K(z,"touchmove",new U.jG(),!1,W.nK)},
h8:function(a){var z,y
for(z=this.c.length,y=0;y<z;++y);}},
jC:{"^":"f:0;a",
$1:function(a){var z,y,x
z=this.a
y=U.cv(a)
x=z.bL(y)
if(x!=null)if(x.ah(y))z.d.l(0,-1,x)
z.a=!0
return}},
jD:{"^":"f:0;a",
$1:function(a){var z,y,x
z=this.a
y=z.d
x=y.h(0,-1)
if(x!=null)x.bm(U.cv(a))
y.l(0,-1,null)
z.a=!1
return}},
jE:{"^":"f:0;a",
$1:function(a){var z,y,x
z=this.a
y=U.cv(a)
x=z.d.h(0,-1)
if(x!=null)x.bk(y)
else{x=z.bL(y)
if(x!=null)if(z.a){x.a.d.aM(y)
x.b.bl(y)}}return}},
jF:{"^":"f:0;a",
$1:function(a){return this.a.h8(a)}},
jG:{"^":"f:0;",
$1:function(a){return J.fH(a)}},
eu:{"^":"e;",
bL:function(a){var z,y,x
z=new U.dA(null,-1,0,0,!1,!1,!1,!1,!1)
z.a=a.a
z.b=a.b
z.c=a.c
z.d=a.d
z.y=a.y
this.d.aM(z)
for(y=this.a,x=y.length-1;x>=0;--x){if(x>=y.length)return H.a(y,x)
if(y[x].bI(z)){if(x>=y.length)return H.a(y,x)
return y[x]}}return}},
et:{"^":"e;a,b",
ah:function(a){this.a.d.aM(a)
this.b=this.b.ah(a)
return!0},
bm:function(a){this.a.d.aM(a)
this.b.bm(a)},
bk:function(a){this.a.d.aM(a)
this.b.bk(a)},
bl:function(a){this.a.d.aM(a)
this.b.bl(a)}},
jH:{"^":"e;"},
dA:{"^":"e;a,b,c,d,e,f,r,x,y",
fv:function(a){var z,y
this.a=-1
z=J.m(a)
y=z.gbP(a)
y=y.gq(y)
y.toString
this.c=y
z=z.gbP(a)
z=z.gu(z)
z.toString
this.d=z
this.y=!0},
w:{
cv:function(a){var z=new U.dA(null,-1,0,0,!1,!1,!1,!1,!1)
z.fv(a)
return z}}}},1]]
setupProgram(dart,0)
J.j=function(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.dS.prototype
return J.dR.prototype}if(typeof a=="string")return J.bv.prototype
if(a==null)return J.ij.prototype
if(typeof a=="boolean")return J.ih.prototype
if(a.constructor==Array)return J.bt.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bw.prototype
return a}if(a instanceof P.e)return a
return J.ca(a)}
J.w=function(a){if(typeof a=="string")return J.bv.prototype
if(a==null)return a
if(a.constructor==Array)return J.bt.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bw.prototype
return a}if(a instanceof P.e)return a
return J.ca(a)}
J.aX=function(a){if(a==null)return a
if(a.constructor==Array)return J.bt.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bw.prototype
return a}if(a instanceof P.e)return a
return J.ca(a)}
J.a5=function(a){if(typeof a=="number")return J.bu.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bA.prototype
return a}
J.bg=function(a){if(typeof a=="number")return J.bu.prototype
if(typeof a=="string")return J.bv.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bA.prototype
return a}
J.c9=function(a){if(typeof a=="string")return J.bv.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bA.prototype
return a}
J.m=function(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.bw.prototype
return a}if(a instanceof P.e)return a
return J.ca(a)}
J.d=function(a,b){if(typeof a=="number"&&typeof b=="number")return a+b
return J.bg(a).v(a,b)}
J.ci=function(a,b){if(typeof a=="number"&&typeof b=="number")return a/b
return J.a5(a).ai(a,b)}
J.J=function(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.j(a).F(a,b)}
J.df=function(a,b){if(typeof a=="number"&&typeof b=="number")return a>=b
return J.a5(a).bV(a,b)}
J.az=function(a,b){if(typeof a=="number"&&typeof b=="number")return a>b
return J.a5(a).bX(a,b)}
J.aZ=function(a,b){if(typeof a=="number"&&typeof b=="number")return a<b
return J.a5(a).aj(a,b)}
J.n=function(a,b){if(typeof a=="number"&&typeof b=="number")return a*b
return J.bg(a).G(a,b)}
J.dg=function(a,b){return J.a5(a).f9(a,b)}
J.r=function(a,b){if(typeof a=="number"&&typeof b=="number")return a-b
return J.a5(a).U(a,b)}
J.fr=function(a,b){if(typeof a=="number"&&typeof b=="number")return(a^b)>>>0
return J.a5(a).fs(a,b)}
J.af=function(a,b){if(typeof b==="number")if(a.constructor==Array||typeof a=="string"||H.fi(a,a[init.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.w(a).h(a,b)}
J.bI=function(a,b,c){if(typeof b==="number")if((a.constructor==Array||H.fi(a,a[init.dispatchPropertyName]))&&!a.immutable$list&&b>>>0===b&&b<a.length)return a[b]=c
return J.aX(a).l(a,b,c)}
J.dh=function(a){return J.m(a).fN(a)}
J.fs=function(a,b,c){return J.m(a).hm(a,b,c)}
J.ft=function(a){return J.a5(a).e7(a)}
J.ar=function(a,b){return J.aX(a).C(a,b)}
J.fu=function(a,b,c,d){return J.m(a).e8(a,b,c,d)}
J.fv=function(a){return J.m(a).bF(a)}
J.fw=function(a,b,c,d,e){return J.m(a).hP(a,b,c,d,e)}
J.di=function(a,b){return J.m(a).b4(a,b)}
J.cj=function(a,b,c){return J.w(a).hR(a,b,c)}
J.b_=function(a,b){return J.aX(a).L(a,b)}
J.fx=function(a){return J.m(a).gcC(a)}
J.dj=function(a){return J.m(a).ghK(a)}
J.fy=function(a){return J.m(a).geh(a)}
J.ck=function(a){return J.m(a).gcF(a)}
J.bi=function(a){return J.m(a).gau(a)}
J.a_=function(a){return J.j(a).gI(a)}
J.fz=function(a){return J.w(a).gD(a)}
J.fA=function(a){return J.w(a).gT(a)}
J.E=function(a){return J.aX(a).gH(a)}
J.a0=function(a){return J.w(a).gi(a)}
J.fB=function(a){return J.m(a).giD(a)}
J.fC=function(a){return J.m(a).giE(a)}
J.dk=function(a){return J.m(a).gN(a)}
J.fD=function(a){return J.m(a).gd5(a)}
J.bj=function(a){return J.m(a).gE(a)}
J.dl=function(a){return J.m(a).gm(a)}
J.bk=function(a){return J.m(a).gu(a)}
J.fE=function(a){return J.m(a).d8(a)}
J.dm=function(a,b,c){return J.m(a).B(a,b,c)}
J.dn=function(a,b){return J.aX(a).af(a,b)}
J.fF=function(a,b,c){return J.c9(a).ez(a,b,c)}
J.fG=function(a,b){return J.j(a).cR(a,b)}
J.fH=function(a){return J.m(a).cW(a)}
J.bl=function(a){return J.aX(a).a2(a)}
J.fI=function(a,b){return J.aX(a).A(a,b)}
J.fJ=function(a,b,c,d){return J.m(a).eJ(a,b,c,d)}
J.fK=function(a,b,c){return J.c9(a).iK(a,b,c)}
J.fL=function(a,b){return J.m(a).iL(a,b)}
J.fM=function(a){return J.m(a).a3(a)}
J.fN=function(a){return J.m(a).a_(a)}
J.b0=function(a,b){return J.m(a).bZ(a,b)}
J.fO=function(a,b){return J.m(a).shO(a,b)}
J.fP=function(a,b){return J.m(a).sbM(a,b)}
J.cl=function(a,b){return J.m(a).sew(a,b)}
J.fQ=function(a,b){return J.m(a).sO(a,b)}
J.dp=function(a,b){return J.m(a).sE(a,b)}
J.fR=function(a,b){return J.m(a).sq(a,b)}
J.fS=function(a,b){return J.m(a).su(a,b)}
J.bm=function(a){return J.m(a).c0(a)}
J.dq=function(a){return J.a5(a).d4(a)}
J.fT=function(a){return J.c9(a).iP(a)}
J.C=function(a){return J.j(a).j(a)}
J.fU=function(a,b){return J.a5(a).iQ(a,b)}
J.cm=function(a){return J.c9(a).eR(a)}
I.aJ=function(a){a.immutable$list=Array
a.fixed$length=Array
return a}
var $=I.p
C.m=W.fV.prototype
C.n=W.cr.prototype
C.b=W.hk.prototype
C.x=J.k.prototype
C.a=J.bt.prototype
C.y=J.dR.prototype
C.f=J.dS.prototype
C.d=J.bu.prototype
C.e=J.bv.prototype
C.F=J.bw.prototype
C.t=J.iV.prototype
C.u=W.jt.prototype
C.l=J.bA.prototype
C.M=W.c2.prototype
C.v=new P.iP()
C.w=new P.k3()
C.c=new P.kP()
C.o=new P.aD(0)
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
C.I=H.p(I.aJ(["*::class","*::dir","*::draggable","*::hidden","*::id","*::inert","*::itemprop","*::itemref","*::itemscope","*::lang","*::spellcheck","*::title","*::translate","A::accesskey","A::coords","A::hreflang","A::name","A::shape","A::tabindex","A::target","A::type","AREA::accesskey","AREA::alt","AREA::coords","AREA::nohref","AREA::shape","AREA::tabindex","AREA::target","AUDIO::controls","AUDIO::loop","AUDIO::mediagroup","AUDIO::muted","AUDIO::preload","BDO::dir","BODY::alink","BODY::bgcolor","BODY::link","BODY::text","BODY::vlink","BR::clear","BUTTON::accesskey","BUTTON::disabled","BUTTON::name","BUTTON::tabindex","BUTTON::type","BUTTON::value","CANVAS::height","CANVAS::width","CAPTION::align","COL::align","COL::char","COL::charoff","COL::span","COL::valign","COL::width","COLGROUP::align","COLGROUP::char","COLGROUP::charoff","COLGROUP::span","COLGROUP::valign","COLGROUP::width","COMMAND::checked","COMMAND::command","COMMAND::disabled","COMMAND::label","COMMAND::radiogroup","COMMAND::type","DATA::value","DEL::datetime","DETAILS::open","DIR::compact","DIV::align","DL::compact","FIELDSET::disabled","FONT::color","FONT::face","FONT::size","FORM::accept","FORM::autocomplete","FORM::enctype","FORM::method","FORM::name","FORM::novalidate","FORM::target","FRAME::name","H1::align","H2::align","H3::align","H4::align","H5::align","H6::align","HR::align","HR::noshade","HR::size","HR::width","HTML::version","IFRAME::align","IFRAME::frameborder","IFRAME::height","IFRAME::marginheight","IFRAME::marginwidth","IFRAME::width","IMG::align","IMG::alt","IMG::border","IMG::height","IMG::hspace","IMG::ismap","IMG::name","IMG::usemap","IMG::vspace","IMG::width","INPUT::accept","INPUT::accesskey","INPUT::align","INPUT::alt","INPUT::autocomplete","INPUT::autofocus","INPUT::checked","INPUT::disabled","INPUT::inputmode","INPUT::ismap","INPUT::list","INPUT::max","INPUT::maxlength","INPUT::min","INPUT::multiple","INPUT::name","INPUT::placeholder","INPUT::readonly","INPUT::required","INPUT::size","INPUT::step","INPUT::tabindex","INPUT::type","INPUT::usemap","INPUT::value","INS::datetime","KEYGEN::disabled","KEYGEN::keytype","KEYGEN::name","LABEL::accesskey","LABEL::for","LEGEND::accesskey","LEGEND::align","LI::type","LI::value","LINK::sizes","MAP::name","MENU::compact","MENU::label","MENU::type","METER::high","METER::low","METER::max","METER::min","METER::value","OBJECT::typemustmatch","OL::compact","OL::reversed","OL::start","OL::type","OPTGROUP::disabled","OPTGROUP::label","OPTION::disabled","OPTION::label","OPTION::selected","OPTION::value","OUTPUT::for","OUTPUT::name","P::align","PRE::width","PROGRESS::max","PROGRESS::min","PROGRESS::value","SELECT::autocomplete","SELECT::disabled","SELECT::multiple","SELECT::name","SELECT::required","SELECT::size","SELECT::tabindex","SOURCE::type","TABLE::align","TABLE::bgcolor","TABLE::border","TABLE::cellpadding","TABLE::cellspacing","TABLE::frame","TABLE::rules","TABLE::summary","TABLE::width","TBODY::align","TBODY::char","TBODY::charoff","TBODY::valign","TD::abbr","TD::align","TD::axis","TD::bgcolor","TD::char","TD::charoff","TD::colspan","TD::headers","TD::height","TD::nowrap","TD::rowspan","TD::scope","TD::valign","TD::width","TEXTAREA::accesskey","TEXTAREA::autocomplete","TEXTAREA::cols","TEXTAREA::disabled","TEXTAREA::inputmode","TEXTAREA::name","TEXTAREA::placeholder","TEXTAREA::readonly","TEXTAREA::required","TEXTAREA::rows","TEXTAREA::tabindex","TEXTAREA::wrap","TFOOT::align","TFOOT::char","TFOOT::charoff","TFOOT::valign","TH::abbr","TH::align","TH::axis","TH::bgcolor","TH::char","TH::charoff","TH::colspan","TH::headers","TH::height","TH::nowrap","TH::rowspan","TH::scope","TH::valign","TH::width","THEAD::align","THEAD::char","THEAD::charoff","THEAD::valign","TR::align","TR::bgcolor","TR::char","TR::charoff","TR::valign","TRACK::default","TRACK::kind","TRACK::label","TRACK::srclang","UL::compact","UL::type","VIDEO::controls","VIDEO::height","VIDEO::loop","VIDEO::mediagroup","VIDEO::muted","VIDEO::preload","VIDEO::width"]),[P.q])
C.J=I.aJ(["HEAD","AREA","BASE","BASEFONT","BR","COL","COLGROUP","EMBED","FRAME","FRAMESET","HR","IMAGE","IMG","INPUT","ISINDEX","LINK","META","PARAM","SOURCE","STYLE","TITLE","WBR"])
C.i=I.aJ([])
C.j=H.p(I.aJ(["bind","if","ref","repeat","syntax"]),[P.q])
C.k=H.p(I.aJ(["A::href","AREA::href","BLOCKQUOTE::cite","BODY::background","COMMAND::icon","DEL::cite","FORM::action","IMG::src","INPUT::src","INS::cite","Q::cite","VIDEO::poster"]),[P.q])
C.K=H.p(I.aJ([]),[P.bz])
C.r=new H.hb(0,{},C.K,[P.bz,null])
C.L=new H.cQ("call")
$.eb="$cachedFunction"
$.ec="$cachedInvocation"
$.ah=0
$.b1=null
$.du=null
$.d9=null
$.fb=null
$.fn=null
$.c8=null
$.cd=null
$.da=null
$.aS=null
$.bc=null
$.bd=null
$.d3=!1
$.x=C.c
$.dL=0
$.at=null
$.cx=null
$.dK=null
$.dJ=null
$.dH=null
$.dG=null
$.dF=null
$.dE=null
$.ag=0
$.bo=null
$.e7=0
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
I.$lazy(y,x,w)}})(["bM","$get$bM",function(){return H.d8("_$dart_dartClosure")},"cE","$get$cE",function(){return H.d8("_$dart_js")},"dO","$get$dO",function(){return H.ic()},"dP","$get$dP",function(){if(typeof WeakMap=="function")var z=new WeakMap()
else{z=$.dL
$.dL=z+1
z="expando$key$"+z}return new P.ht(null,z)},"ev","$get$ev",function(){return H.al(H.c1({
toString:function(){return"$receiver$"}}))},"ew","$get$ew",function(){return H.al(H.c1({$method$:null,
toString:function(){return"$receiver$"}}))},"ex","$get$ex",function(){return H.al(H.c1(null))},"ey","$get$ey",function(){return H.al(function(){var $argumentsExpr$='$arguments$'
try{null.$method$($argumentsExpr$)}catch(z){return z.message}}())},"eC","$get$eC",function(){return H.al(H.c1(void 0))},"eD","$get$eD",function(){return H.al(function(){var $argumentsExpr$='$arguments$'
try{(void 0).$method$($argumentsExpr$)}catch(z){return z.message}}())},"eA","$get$eA",function(){return H.al(H.eB(null))},"ez","$get$ez",function(){return H.al(function(){try{null.$method$}catch(z){return z.message}}())},"eF","$get$eF",function(){return H.al(H.eB(void 0))},"eE","$get$eE",function(){return H.al(function(){try{(void 0).$method$}catch(z){return z.message}}())},"cU","$get$cU",function(){return P.jO()},"br","$get$br",function(){var z,y
z=P.b7
y=new P.an(0,P.jN(),null,[z])
y.fF(null,z)
return y},"be","$get$be",function(){return[]},"eQ","$get$eQ",function(){return P.dV(["A","ABBR","ACRONYM","ADDRESS","AREA","ARTICLE","ASIDE","AUDIO","B","BDI","BDO","BIG","BLOCKQUOTE","BR","BUTTON","CANVAS","CAPTION","CENTER","CITE","CODE","COL","COLGROUP","COMMAND","DATA","DATALIST","DD","DEL","DETAILS","DFN","DIR","DIV","DL","DT","EM","FIELDSET","FIGCAPTION","FIGURE","FONT","FOOTER","FORM","H1","H2","H3","H4","H5","H6","HEADER","HGROUP","HR","I","IFRAME","IMG","INPUT","INS","KBD","LABEL","LEGEND","LI","MAP","MARK","MENU","METER","NAV","NOBR","OL","OPTGROUP","OPTION","OUTPUT","P","PRE","PROGRESS","Q","S","SAMP","SECTION","SELECT","SMALL","SOURCE","SPAN","STRIKE","STRONG","SUB","SUMMARY","SUP","TABLE","TBODY","TD","TEXTAREA","TFOOT","TH","THEAD","TIME","TR","TRACK","TT","U","UL","VAR","VIDEO","WBR"],null)},"cY","$get$cY",function(){return P.bS()},"dD","$get$dD",function(){return P.je("^\\S+$",!0,!1)},"d7","$get$d7",function(){return P.f9(self)},"cW","$get$cW",function(){return H.d8("_$dart_dartObject")},"d0","$get$d0",function(){return function DartObject(a){this.o=a}},"U","$get$U",function(){return W.m7().devicePixelRatio},"aa","$get$aa",function(){var z=$.$get$U()
if(typeof z!=="number")return H.l(z)
return 80*z},"o","$get$o",function(){var z=$.$get$U()
if(typeof z!=="number")return H.l(z)
return 34*z},"O","$get$O",function(){var z=$.$get$U()
if(typeof z!=="number")return H.l(z)
return 10*z},"aB","$get$aB",function(){var z=$.$get$U()
if(typeof z!=="number")return H.l(z)
return 25*z},"bK","$get$bK",function(){var z=$.$get$U()
if(typeof z!=="number")return H.l(z)
return 10*z},"cp","$get$cp",function(){return $.$get$O()},"ao","$get$ao",function(){return P.bS()}])
I=I.$finishIsolateConstructor(I)
$=new I()
init.metadata=["e",null,"value","canvasId","error","_","stackTrace","attributeName","invocation","object","x","data","element","context","o","arg1","arg2","arg3","each","sender","arg4","isolate","arg","language","time","attr","n","callback","captureThis","self","arguments","numberOfArguments","jsonString","closure"]
init.types=[{func:1,args:[,]},{func:1,v:true},{func:1},{func:1,v:true,args:[P.e],opt:[P.by]},{func:1,v:true,args:[{func:1,v:true}]},{func:1,args:[,,]},{func:1,ret:P.q,args:[P.y]},{func:1,args:[P.aM]},{func:1,ret:P.bF,args:[W.N,P.q,P.q,W.cX]},{func:1,args:[P.q,,]},{func:1,args:[,P.q]},{func:1,args:[P.q]},{func:1,args:[{func:1,v:true}]},{func:1,args:[,],opt:[,]},{func:1,v:true,args:[,P.by]},{func:1,args:[P.bz,,]},{func:1,args:[W.N]},{func:1,args:[P.bF,P.aM]},{func:1,v:true,args:[W.t,W.t]},{func:1,v:true,args:[P.e]},{func:1,ret:P.y,args:[P.q]},{func:1,ret:P.ap,args:[P.q]},{func:1,ret:P.e,args:[,]},{func:1,v:true,args:[P.q,P.q]},{func:1,ret:P.q,args:[P.q,P.q]},{func:1,ret:P.q,args:[P.q]}]
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
if(x==y)H.m5(d||a)
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
Isolate.aJ=a.aJ
Isolate.Q=a.Q
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
if(typeof dartMainRunner==="function")dartMainRunner(function(b){H.fp(U.fk(),b)},[])
else (function(b){H.fp(U.fk(),b)})([])})})()/*
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
    return NetTango_Save(canvasId);
  },


  /// Restores a workspace to a previously saved state (json object).
  /// Note, for now this is just an alias of the NetTango.init function.
  restore : function(canvasId, json) {
    NetTango_InitWorkspace(canvasId, JSON.stringify(json));
  },


  _relayCallback : function(canvasId) {
    if (canvasId in NetTango._callbacks) {
      NetTango._callbacks[canvasId](canvasId);
    }
  },

  _callbacks : { }
}
