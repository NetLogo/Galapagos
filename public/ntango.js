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
init.leafTags[b8[b2]]=false}}b5.$deferredAction()}if(b5.$isi)b5.$deferredAction()}var a3=Object.keys(a4.pending)
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
if(a0==="v"){processStatics(init.statics[b1]=b2.v,b3)
delete b2.v}else if(a1===43){w[g]=a0.substring(1)
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
if(a7)b6[b4+"*"]=d[0]}}function tearOffGetter(c,d,e,f){return f?new Function("funcs","reflectionInfo","name","H","c","return function tearOff_"+e+y+++"(x) {"+"if (c === null) c = "+"H.cI"+"("+"this, funcs, reflectionInfo, false, [x], name);"+"return new c(this, funcs[0], x, name);"+"}")(c,d,e,H,null):new Function("funcs","reflectionInfo","name","H","c","return function tearOff_"+e+y+++"() {"+"if (c === null) c = "+"H.cI"+"("+"this, funcs, reflectionInfo, false, [], name);"+"return new c(this, funcs[0], null, name);"+"}")(c,d,e,H,null)}function tearOff(c,d,e,f,a0){var g
return e?function(){if(g===void 0)g=H.cI(this,c,d,true,[],f).prototype
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
x.push([p,o,i,h,n,j,k,m])}finishClasses(s)}I.K=function(){}
var dart=[["","",,H,{"^":"",lx:{"^":"e;a"}}],["","",,J,{"^":"",
k:function(a){return void 0},
bV:function(a,b,c,d){return{i:a,p:b,e:c,x:d}},
bS:function(a){var z,y,x,w,v
z=a[init.dispatchPropertyName]
if(z==null)if($.cM==null){H.ks()
z=a[init.dispatchPropertyName]}if(z!=null){y=z.p
if(!1===y)return z.i
if(!0===y)return a
x=Object.getPrototypeOf(a)
if(y===x)return z.i
if(z.e===x)throw H.c(new P.e8("Return interceptor for "+H.b(y(a,z))))}w=a.constructor
v=w==null?null:w[$.$get$cd()]
if(v!=null)return v
v=H.kC(a)
if(v!=null)return v
if(typeof a=="function")return C.D
y=Object.getPrototypeOf(a)
if(y==null)return C.r
if(y===Object.prototype)return C.r
if(typeof w=="function"){Object.defineProperty(w,$.$get$cd(),{value:C.k,enumerable:false,writable:true,configurable:true})
return C.k}return C.k},
i:{"^":"e;",
B:function(a,b){return a===b},
gE:function(a){return H.al(a)},
k:["eF",function(a){return H.bH(a)}],
cp:["eE",function(a,b){throw H.c(P.dx(a,b.gdX(),b.ge4(),b.gdY(),null))},null,"ghV",2,0,null,6],
"%":"CanvasGradient|CanvasPattern|Client|DOMError|DOMImplementation|FileError|MediaError|NavigatorUserMediaError|PositionError|PushMessageData|SQLError|SVGAnimatedEnumeration|SVGAnimatedLength|SVGAnimatedLengthList|SVGAnimatedNumber|SVGAnimatedNumberList|SVGAnimatedString|WebGLRenderingContext|WindowClient"},
hg:{"^":"i;",
k:function(a){return String(a)},
gE:function(a){return a?519018:218159},
$iscH:1},
hj:{"^":"i;",
B:function(a,b){return null==b},
k:function(a){return"null"},
gE:function(a){return 0},
cp:[function(a,b){return this.eE(a,b)},null,"ghV",2,0,null,6]},
ce:{"^":"i;",
gE:function(a){return 0},
k:["eH",function(a){return String(a)}],
$ishk:1},
hU:{"^":"ce;"},
bn:{"^":"ce;"},
bi:{"^":"ce;",
k:function(a){var z=a[$.$get$bx()]
return z==null?this.eH(a):J.A(z)},
$isca:1,
$S:function(){return{func:1,opt:[,,,,,,,,,,,,,,,,]}}},
bf:{"^":"i;$ti",
dH:function(a,b){if(!!a.immutable$list)throw H.c(new P.t(b))},
aN:function(a,b){if(!!a.fixed$length)throw H.c(new P.t(b))},
D:function(a,b){this.aN(a,"add")
a.push(b)},
ay:function(a,b){var z
this.aN(a,"removeAt")
z=a.length
if(b>=z)throw H.c(P.aZ(b,null,null))
return a.splice(b,1)[0]},
H:function(a,b){var z
this.aN(a,"remove")
for(z=0;z<a.length;++z)if(J.N(a[z],b)){a.splice(z,1)
return!0}return!1},
P:function(a,b){var z
this.aN(a,"addAll")
for(z=J.L(b);z.u();)a.push(z.gw())},
am:function(a,b){return new H.bk(a,b,[H.H(a,0),null])},
O:function(a,b){if(b<0||b>=a.length)return H.a(a,b)
return a[b]},
ghv:function(a){if(a.length>0)return a[0]
throw H.c(H.cc())},
a2:function(a,b,c,d,e){var z,y,x
this.dH(a,"setRange")
P.cr(b,c,a.length,null,null,null)
z=c-b
if(z===0)return
if(e<0)H.y(P.E(e,0,null,"skipCount",null))
if(e+z>d.length)throw H.c(H.dm())
if(e<b)for(y=z-1;y>=0;--y){x=e+y
if(x<0||x>=d.length)return H.a(d,x)
a[b+y]=d[x]}else for(y=0;y<z;++y){x=e+y
if(x<0||x>=d.length)return H.a(d,x)
a[b+y]=d[x]}},
dD:function(a,b){var z,y
z=a.length
for(y=0;y<z;++y){if(b.$1(a[y])===!0)return!0
if(a.length!==z)throw H.c(new P.ah(a))}return!1},
N:function(a,b){var z
for(z=0;z<a.length;++z)if(J.N(a[z],b))return!0
return!1},
k:function(a){return P.bB(a,"[","]")},
gK:function(a){return new J.fm(a,a.length,0,null)},
gE:function(a){return H.al(a)},
gj:function(a){return a.length},
sj:function(a,b){this.aN(a,"set length")
if(b<0)throw H.c(P.E(b,0,null,"newLength",null))
a.length=b},
h:function(a,b){if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(H.F(a,b))
if(b>=a.length||b<0)throw H.c(H.F(a,b))
return a[b]},
n:function(a,b,c){this.dH(a,"indexed set")
if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(H.F(a,b))
if(b>=a.length||b<0)throw H.c(H.F(a,b))
a[b]=c},
$isR:1,
$asR:I.K,
$isf:1,
$asf:null,
$isj:1,
$asj:null},
lw:{"^":"bf;$ti"},
fm:{"^":"e;a,b,c,d",
gw:function(){return this.d},
u:function(){var z,y,x
z=this.a
y=z.length
if(this.b!==y)throw H.c(H.z(z))
x=this.c
if(x>=y){this.d=null
return!1}this.d=z[x]
this.c=x+1
return!0}},
bg:{"^":"i;",
ghM:function(a){return a===0?1/a<0:a<0},
cD:function(a){var z
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){z=a<0?Math.ceil(a):Math.floor(a)
return z+0}throw H.c(new P.t(""+a+".toInt()"))},
aZ:function(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw H.c(new P.t(""+a+".round()"))},
i6:function(a,b){var z
if(b>20)throw H.c(P.E(b,0,20,"fractionDigits",null))
z=a.toFixed(b)
if(a===0&&this.ghM(a))return"-"+z
return z},
k:function(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gE:function(a){return a&0x1FFFFFFF},
i:function(a,b){if(typeof b!=="number")throw H.c(H.I(b))
return a+b},
G:function(a,b){if(typeof b!=="number")throw H.c(H.I(b))
return a-b},
C:function(a,b){if(typeof b!=="number")throw H.c(H.I(b))
return a*b},
bJ:function(a,b){if((a|0)===a)if(b>=1||!1)return a/b|0
return this.du(a,b)},
bq:function(a,b){return(a|0)===a?a/b|0:this.du(a,b)},
du:function(a,b){var z=a/b
if(z>=-2147483648&&z<=2147483647)return z|0
if(z>0){if(z!==1/0)return Math.floor(z)}else if(z>-1/0)return Math.ceil(z)
throw H.c(new P.t("Result of truncating division is "+H.b(z)+": "+H.b(a)+" ~/ "+b))},
ey:function(a,b){if(b<0)throw H.c(H.I(b))
return b>31?0:a<<b>>>0},
ez:function(a,b){var z
if(b<0)throw H.c(H.I(b))
if(a>0)z=b>31?0:a>>>b
else{z=b>31?31:b
z=a>>z>>>0}return z},
c9:function(a,b){var z
if(a>0)z=b>31?0:a>>>b
else{z=b>31?31:b
z=a>>z>>>0}return z},
eP:function(a,b){if(typeof b!=="number")throw H.c(H.I(b))
return(a^b)>>>0},
X:function(a,b){if(typeof b!=="number")throw H.c(H.I(b))
return a<b},
an:function(a,b){if(typeof b!=="number")throw H.c(H.I(b))
return a>b},
$isb6:1},
dp:{"^":"bg;",$isb6:1,$isr:1},
hh:{"^":"bg;",$isb6:1},
bh:{"^":"i;",
cf:function(a,b){if(b<0)throw H.c(H.F(a,b))
if(b>=a.length)H.y(H.F(a,b))
return a.charCodeAt(b)},
aE:function(a,b){if(b>=a.length)throw H.c(H.F(a,b))
return a.charCodeAt(b)},
hR:function(a,b,c){var z,y
if(c>b.length)throw H.c(P.E(c,0,b.length,null,null))
z=a.length
if(c+z>b.length)return
for(y=0;y<z;++y)if(this.aE(b,c+y)!==this.aE(a,y))return
return new H.ij(c,b,a)},
i:function(a,b){if(typeof b!=="string")throw H.c(P.d_(b,null,null))
return a+b},
hs:function(a,b){var z,y
z=b.length
y=a.length
if(z>y)return!1
return b===this.cL(a,y-z)},
eB:function(a,b,c){var z
if(c>a.length)throw H.c(P.E(c,0,a.length,null,null))
if(typeof b==="string"){z=c+b.length
if(z>a.length)return!1
return b===a.substring(c,z)}return J.fa(b,a,c)!=null},
eA:function(a,b){return this.eB(a,b,0)},
ac:function(a,b,c){var z
if(typeof b!=="number"||Math.floor(b)!==b)H.y(H.I(b))
if(c==null)c=a.length
if(typeof c!=="number"||Math.floor(c)!==c)H.y(H.I(c))
z=J.ae(b)
if(z.X(b,0))throw H.c(P.aZ(b,null,null))
if(z.an(b,c))throw H.c(P.aZ(b,null,null))
if(J.bt(c,a.length))throw H.c(P.aZ(c,null,null))
return a.substring(b,c)},
cL:function(a,b){return this.ac(a,b,null)},
i5:function(a){return a.toLowerCase()},
ef:function(a){var z,y,x,w,v
z=a.trim()
y=z.length
if(y===0)return z
if(this.aE(z,0)===133){x=J.hl(z,1)
if(x===y)return""}else x=0
w=y-1
v=this.cf(z,w)===133?J.hm(z,w):y
if(x===0&&v===y)return z
return z.substring(x,v)},
C:function(a,b){var z,y
if(typeof b!=="number")return H.d(b)
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw H.c(C.u)
for(z=a,y="";!0;){if((b&1)===1)y=z+y
b=b>>>1
if(b===0)break
z+=z}return y},
ha:function(a,b,c){if(c>a.length)throw H.c(P.E(c,0,a.length,null,null))
return H.kN(a,b,c)},
k:function(a){return a},
gE:function(a){var z,y,x
for(z=a.length,y=0,x=0;x<z;++x){y=536870911&y+a.charCodeAt(x)
y=536870911&y+((524287&y)<<10)
y^=y>>6}y=536870911&y+((67108863&y)<<3)
y^=y>>11
return 536870911&y+((16383&y)<<15)},
gj:function(a){return a.length},
h:function(a,b){if(typeof b!=="number"||Math.floor(b)!==b)throw H.c(H.F(a,b))
if(b>=a.length||b<0)throw H.c(H.F(a,b))
return a[b]},
$isR:1,
$asR:I.K,
$isp:1,
v:{
dq:function(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
hl:function(a,b){var z,y
for(z=a.length;b<z;){y=C.d.aE(a,b)
if(y!==32&&y!==13&&!J.dq(y))break;++b}return b},
hm:function(a,b){var z,y
for(;b>0;b=z){z=b-1
y=C.d.cf(a,z)
if(y!==32&&y!==13&&!J.dq(y))break}return b}}}}],["","",,H,{"^":"",
cc:function(){return new P.X("No element")},
hf:function(){return new P.X("Too many elements")},
dm:function(){return new P.X("Too few elements")},
j:{"^":"Z;$ti",$asj:null},
aW:{"^":"j;$ti",
gK:function(a){return new H.cj(this,this.gj(this),0,null)},
cH:function(a,b){return this.eG(0,b)},
am:function(a,b){return new H.bk(this,b,[H.G(this,"aW",0),null])},
b0:function(a,b){var z,y,x
z=H.o([],[H.G(this,"aW",0)])
C.a.sj(z,this.gj(this))
for(y=0;y<this.gj(this);++y){x=this.O(0,y)
if(y>=z.length)return H.a(z,y)
z[y]=x}return z},
cE:function(a){return this.b0(a,!0)}},
cs:{"^":"aW;a,b,c,$ti",
gfe:function(){var z,y
z=J.ag(this.a)
y=this.c
if(y==null||y>z)return z
return y},
gfU:function(){var z,y
z=J.ag(this.a)
y=this.b
if(y>z)return z
return y},
gj:function(a){var z,y,x
z=J.ag(this.a)
y=this.b
if(y>=z)return 0
x=this.c
if(x==null||x>=z)return z-y
if(typeof x!=="number")return x.G()
return x-y},
O:function(a,b){var z,y
z=this.gfU()+b
if(b>=0){y=this.gfe()
if(typeof y!=="number")return H.d(y)
y=z>=y}else y=!0
if(y)throw H.c(P.as(b,this,"index",null,null))
return J.cS(this.a,z)},
i4:function(a,b){var z,y,x
if(b<0)H.y(P.E(b,0,null,"count",null))
z=this.c
y=this.b
x=y+b
if(z==null)return H.dS(this.a,y,x,H.H(this,0))
else{if(z<x)return this
return H.dS(this.a,y,x,H.H(this,0))}},
b0:function(a,b){var z,y,x,w,v,u,t,s,r
z=this.b
y=this.a
x=J.B(y)
w=x.gj(y)
v=this.c
if(v!=null&&v<w)w=v
if(typeof w!=="number")return w.G()
u=w-z
if(u<0)u=0
t=H.o(new Array(u),this.$ti)
for(s=0;s<u;++s){r=x.O(y,z+s)
if(s>=t.length)return H.a(t,s)
t[s]=r
if(x.gj(y)<w)throw H.c(new P.ah(this))}return t},
eV:function(a,b,c,d){var z,y
z=this.b
if(z<0)H.y(P.E(z,0,null,"start",null))
y=this.c
if(y!=null){if(y<0)H.y(P.E(y,0,null,"end",null))
if(z>y)throw H.c(P.E(z,0,y,"start",null))}},
v:{
dS:function(a,b,c,d){var z=new H.cs(a,b,c,[d])
z.eV(a,b,c,d)
return z}}},
cj:{"^":"e;a,b,c,d",
gw:function(){return this.d},
u:function(){var z,y,x,w
z=this.a
y=J.B(z)
x=y.gj(z)
if(this.b!==x)throw H.c(new P.ah(z))
w=this.c
if(w>=x){this.d=null
return!1}this.d=y.O(z,w);++this.c
return!0}},
cl:{"^":"Z;a,b,$ti",
gK:function(a){return new H.hD(null,J.L(this.a),this.b,this.$ti)},
gj:function(a){return J.ag(this.a)},
$asZ:function(a,b){return[b]},
v:{
bD:function(a,b,c,d){if(!!J.k(a).$isj)return new H.de(a,b,[c,d])
return new H.cl(a,b,[c,d])}}},
de:{"^":"cl;a,b,$ti",$isj:1,
$asj:function(a,b){return[b]}},
hD:{"^":"dn;a,b,c,$ti",
u:function(){var z=this.b
if(z.u()){this.a=this.c.$1(z.gw())
return!0}this.a=null
return!1},
gw:function(){return this.a}},
bk:{"^":"aW;a,b,$ti",
gj:function(a){return J.ag(this.a)},
O:function(a,b){return this.b.$1(J.cS(this.a,b))},
$asaW:function(a,b){return[b]},
$asj:function(a,b){return[b]},
$asZ:function(a,b){return[b]}},
ea:{"^":"Z;a,b,$ti",
gK:function(a){return new H.iB(J.L(this.a),this.b,this.$ti)},
am:function(a,b){return new H.cl(this,b,[H.H(this,0),null])}},
iB:{"^":"dn;a,b,$ti",
u:function(){var z,y
for(z=this.a,y=this.b;z.u();)if(y.$1(z.gw())===!0)return!0
return!1},
gw:function(){return this.a.gw()}},
di:{"^":"e;$ti",
sj:function(a,b){throw H.c(new P.t("Cannot change the length of a fixed-length list"))},
D:function(a,b){throw H.c(new P.t("Cannot add to a fixed-length list"))},
ay:function(a,b){throw H.c(new P.t("Cannot remove from a fixed-length list"))}},
ct:{"^":"e;fu:a<",
B:function(a,b){if(b==null)return!1
return b instanceof H.ct&&J.N(this.a,b.a)},
gE:function(a){var z,y
z=this._hashCode
if(z!=null)return z
y=J.T(this.a)
if(typeof y!=="number")return H.d(y)
z=536870911&664597*y
this._hashCode=z
return z},
k:function(a){return'Symbol("'+H.b(this.a)+'")'}}}],["","",,H,{"^":"",
bq:function(a,b){var z=a.aP(b)
if(!init.globalState.d.cy)init.globalState.f.b_()
return z},
eZ:function(a,b){var z,y,x,w,v,u
z={}
z.a=b
if(b==null){b=[]
z.a=b
y=b}else y=b
if(!J.k(y).$isf)throw H.c(P.aR("Arguments to main must be a List: "+H.b(y)))
init.globalState=new H.jq(0,0,1,null,null,null,null,null,null,null,null,null,a)
y=init.globalState
x=self.window==null
w=self.Worker
v=x&&!!self.postMessage
y.x=v
v=!v
if(v)w=w!=null&&$.$get$dk()!=null
else w=!0
y.y=w
y.r=x&&v
y.f=new H.iX(P.ck(null,H.bp),0)
x=P.r
y.z=new H.U(0,null,null,null,null,null,0,[x,H.cA])
y.ch=new H.U(0,null,null,null,null,null,0,[x,null])
if(y.x===!0){w=new H.jp()
y.Q=w
self.onmessage=function(c,d){return function(e){c(d,e)}}(H.h8,w)
self.dartPrint=self.dartPrint||function(c){return function(d){if(self.console&&self.console.log)self.console.log(d)
else self.postMessage(c(d))}}(H.jr)}if(init.globalState.x===!0)return
y=init.globalState.a++
w=P.a8(null,null,null,x)
v=new H.bJ(0,null,!1)
u=new H.cA(y,new H.U(0,null,null,null,null,null,0,[x,H.bJ]),w,init.createNewIsolate(),v,new H.aB(H.bX()),new H.aB(H.bX()),!1,!1,[],P.a8(null,null,null,null),null,null,!1,!0,P.a8(null,null,null,null))
w.D(0,0)
u.cT(0,v)
init.globalState.e=u
init.globalState.d=u
if(H.ay(a,{func:1,args:[,]}))u.aP(new H.kL(z,a))
else if(H.ay(a,{func:1,args:[,,]}))u.aP(new H.kM(z,a))
else u.aP(a)
init.globalState.f.b_()},
hc:function(){var z=init.currentScript
if(z!=null)return String(z.src)
if(init.globalState.x===!0)return H.hd()
return},
hd:function(){var z,y
z=new Error().stack
if(z==null){z=function(){try{throw new Error()}catch(x){return x.stack}}()
if(z==null)throw H.c(new P.t("No stack trace"))}y=z.match(new RegExp("^ *at [^(]*\\((.*):[0-9]*:[0-9]*\\)$","m"))
if(y!=null)return y[1]
y=z.match(new RegExp("^[^@]*@(.*):[0-9]*$","m"))
if(y!=null)return y[1]
throw H.c(new P.t('Cannot extract URI from "'+z+'"'))},
h8:[function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o,n
z=new H.bM(!0,[]).ai(b.data)
y=J.B(z)
switch(y.h(z,"command")){case"start":init.globalState.b=y.h(z,"id")
x=y.h(z,"functionName")
w=x==null?init.globalState.cx:init.globalFunctions[x]()
v=y.h(z,"args")
u=new H.bM(!0,[]).ai(y.h(z,"msg"))
t=y.h(z,"isSpawnUri")
s=y.h(z,"startPaused")
r=new H.bM(!0,[]).ai(y.h(z,"replyTo"))
y=init.globalState.a++
q=P.r
p=P.a8(null,null,null,q)
o=new H.bJ(0,null,!1)
n=new H.cA(y,new H.U(0,null,null,null,null,null,0,[q,H.bJ]),p,init.createNewIsolate(),o,new H.aB(H.bX()),new H.aB(H.bX()),!1,!1,[],P.a8(null,null,null,null),null,null,!1,!0,P.a8(null,null,null,null))
p.D(0,0)
n.cT(0,o)
init.globalState.f.a.a3(new H.bp(n,new H.h9(w,v,u,t,s,r),"worker-start"))
init.globalState.d=n
init.globalState.f.b_()
break
case"spawn-worker":break
case"message":if(y.h(z,"port")!=null)J.aQ(y.h(z,"port"),y.h(z,"msg"))
init.globalState.f.b_()
break
case"close":init.globalState.ch.H(0,$.$get$dl().h(0,a))
a.terminate()
init.globalState.f.b_()
break
case"log":H.h7(y.h(z,"msg"))
break
case"print":if(init.globalState.x===!0){y=init.globalState.Q
q=P.at(["command","print","msg",z])
q=new H.aI(!0,P.b0(null,P.r)).Y(q)
y.toString
self.postMessage(q)}else P.bW(y.h(z,"msg"))
break
case"error":throw H.c(y.h(z,"msg"))}},null,null,4,0,null,15,1],
h7:function(a){var z,y,x,w
if(init.globalState.x===!0){y=init.globalState.Q
x=P.at(["command","log","msg",a])
x=new H.aI(!0,P.b0(null,P.r)).Y(x)
y.toString
self.postMessage(x)}else try{self.console.log(a)}catch(w){H.C(w)
z=H.S(w)
y=P.bz(z)
throw H.c(y)}},
ha:function(a,b,c,d,e,f){var z,y,x,w
z=init.globalState.d
y=z.a
$.dG=$.dG+("_"+y)
$.dH=$.dH+("_"+y)
y=z.e
x=init.globalState.d.a
w=z.f
J.aQ(f,["spawned",new H.bO(y,x),w,z.r])
x=new H.hb(a,b,c,d,z)
if(e===!0){z.dC(w,w)
init.globalState.f.a.a3(new H.bp(z,x,"start isolate"))}else x.$0()},
jU:function(a){return new H.bM(!0,[]).ai(new H.aI(!1,P.b0(null,P.r)).Y(a))},
kL:{"^":"h:2;a,b",
$0:function(){this.b.$1(this.a.a)}},
kM:{"^":"h:2;a,b",
$0:function(){this.b.$2(this.a.a,null)}},
jq:{"^":"e;a,b,c,d,e,f,r,x,y,z,Q,ch,cx",v:{
jr:[function(a){var z=P.at(["command","print","msg",a])
return new H.aI(!0,P.b0(null,P.r)).Y(z)},null,null,2,0,null,7]}},
cA:{"^":"e;a,b,c,hO:d<,hb:e<,f,r,hG:x?,aU:y<,hh:z<,Q,ch,cx,cy,db,dx",
dC:function(a,b){if(!this.f.B(0,a))return
if(this.Q.D(0,b)&&!this.y)this.y=!0
this.ca()},
i1:function(a){var z,y,x,w,v,u
if(!this.y)return
z=this.Q
z.H(0,a)
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
if(w===y.c)y.dc();++y.d}this.y=!1}this.ca()},
h_:function(a,b){var z,y,x
if(this.ch==null)this.ch=[]
for(z=J.k(a),y=0;x=this.ch,y<x.length;y+=2)if(z.B(a,x[y])){z=this.ch
x=y+1
if(x>=z.length)return H.a(z,x)
z[x]=b
return}x.push(a)
this.ch.push(b)},
i0:function(a){var z,y,x
if(this.ch==null)return
for(z=J.k(a),y=0;x=this.ch,y<x.length;y+=2)if(z.B(a,x[y])){z=this.ch
x=y+2
z.toString
if(typeof z!=="object"||z===null||!!z.fixed$length)H.y(new P.t("removeRange"))
P.cr(y,x,z.length,null,null,null)
z.splice(y,x-y)
return}},
ex:function(a,b){if(!this.r.B(0,a))return
this.db=b},
hz:function(a,b,c){var z=J.k(b)
if(!z.B(b,0))z=z.B(b,1)&&!this.cy
else z=!0
if(z){J.aQ(a,c)
return}z=this.cx
if(z==null){z=P.ck(null,null)
this.cx=z}z.a3(new H.jf(a,c))},
hy:function(a,b){var z
if(!this.r.B(0,a))return
z=J.k(b)
if(!z.B(b,0))z=z.B(b,1)&&!this.cy
else z=!0
if(z){this.cl()
return}z=this.cx
if(z==null){z=P.ck(null,null)
this.cx=z}z.a3(this.ghP())},
hA:function(a,b){var z,y,x
z=this.dx
if(z.a===0){if(this.db===!0&&this===init.globalState.e)return
if(self.console&&self.console.error)self.console.error(a,b)
else{P.bW(a)
if(b!=null)P.bW(b)}return}y=new Array(2)
y.fixed$length=Array
y[0]=J.A(a)
y[1]=b==null?null:J.A(b)
for(x=new P.ep(z,z.r,null,null),x.c=z.e;x.u();)J.aQ(x.d,y)},
aP:function(a){var z,y,x,w,v,u,t
z=init.globalState.d
init.globalState.d=this
$=this.d
y=null
x=this.cy
this.cy=!0
try{y=a.$0()}catch(u){w=H.C(u)
v=H.S(u)
this.hA(w,v)
if(this.db===!0){this.cl()
if(this===init.globalState.e)throw u}}finally{this.cy=x
init.globalState.d=z
if(z!=null)$=z.ghO()
if(this.cx!=null)for(;t=this.cx,!t.gJ(t);)this.cx.e8().$0()}return y},
hw:function(a){var z=J.B(a)
switch(z.h(a,0)){case"pause":this.dC(z.h(a,1),z.h(a,2))
break
case"resume":this.i1(z.h(a,1))
break
case"add-ondone":this.h_(z.h(a,1),z.h(a,2))
break
case"remove-ondone":this.i0(z.h(a,1))
break
case"set-errors-fatal":this.ex(z.h(a,1),z.h(a,2))
break
case"ping":this.hz(z.h(a,1),z.h(a,2),z.h(a,3))
break
case"kill":this.hy(z.h(a,1),z.h(a,2))
break
case"getErrors":this.dx.D(0,z.h(a,1))
break
case"stopErrors":this.dx.H(0,z.h(a,1))
break}},
dW:function(a){return this.b.h(0,a)},
cT:function(a,b){var z=this.b
if(z.a_(a))throw H.c(P.bz("Registry: ports must be registered only once."))
z.n(0,a,b)},
ca:function(){var z=this.b
if(z.gj(z)-this.c.a>0||this.y||!this.x)init.globalState.z.n(0,this.a,this)
else this.cl()},
cl:[function(){var z,y,x,w,v
z=this.cx
if(z!=null)z.ah(0)
for(z=this.b,y=z.gcG(z),y=y.gK(y);y.u();)y.gw().f7()
z.ah(0)
this.c.ah(0)
init.globalState.z.H(0,this.a)
this.dx.ah(0)
if(this.ch!=null){for(x=0;z=this.ch,y=z.length,x<y;x+=2){w=z[x]
v=x+1
if(v>=y)return H.a(z,v)
J.aQ(w,z[v])}this.ch=null}},"$0","ghP",0,0,1]},
jf:{"^":"h:1;a,b",
$0:[function(){J.aQ(this.a,this.b)},null,null,0,0,null,"call"]},
iX:{"^":"e;a,b",
hi:function(){var z=this.a
if(z.b===z.c)return
return z.e8()},
ea:function(){var z,y,x
z=this.hi()
if(z==null){if(init.globalState.e!=null)if(init.globalState.z.a_(init.globalState.e.a))if(init.globalState.r===!0){y=init.globalState.e.b
y=y.gJ(y)}else y=!1
else y=!1
else y=!1
if(y)H.y(P.bz("Program exited with open ReceivePorts."))
y=init.globalState
if(y.x===!0){x=y.z
x=x.gJ(x)&&y.f.b===0}else x=!1
if(x){y=y.Q
x=P.at(["command","close"])
x=new H.aI(!0,new P.eq(0,null,null,null,null,null,0,[null,P.r])).Y(x)
y.toString
self.postMessage(x)}return!1}z.hZ()
return!0},
dr:function(){if(self.window!=null)new H.iY(this).$0()
else for(;this.ea(););},
b_:function(){var z,y,x,w,v
if(init.globalState.x!==!0)this.dr()
else try{this.dr()}catch(x){z=H.C(x)
y=H.S(x)
w=init.globalState.Q
v=P.at(["command","error","msg",H.b(z)+"\n"+H.b(y)])
v=new H.aI(!0,P.b0(null,P.r)).Y(v)
w.toString
self.postMessage(v)}}},
iY:{"^":"h:1;a",
$0:function(){if(!this.a.ea())return
P.iq(C.m,this)}},
bp:{"^":"e;a,b,c",
hZ:function(){var z=this.a
if(z.gaU()){z.ghh().push(this)
return}z.aP(this.b)}},
jp:{"^":"e;"},
h9:{"^":"h:2;a,b,c,d,e,f",
$0:function(){H.ha(this.a,this.b,this.c,this.d,this.e,this.f)}},
hb:{"^":"h:1;a,b,c,d,e",
$0:function(){var z,y
z=this.e
z.shG(!0)
if(this.d!==!0)this.a.$1(this.c)
else{y=this.a
if(H.ay(y,{func:1,args:[,,]}))y.$2(this.b,this.c)
else if(H.ay(y,{func:1,args:[,]}))y.$1(this.b)
else y.$0()}z.ca()}},
ec:{"^":"e;"},
bO:{"^":"ec;b,a",
bD:function(a,b){var z,y,x
z=init.globalState.z.h(0,this.a)
if(z==null)return
y=this.b
if(y.gdh())return
x=H.jU(b)
if(z.ghb()===y){z.hw(x)
return}init.globalState.f.a.a3(new H.bp(z,new H.jt(this,x),"receive"))},
B:function(a,b){if(b==null)return!1
return b instanceof H.bO&&J.N(this.b,b.b)},
gE:function(a){return this.b.gc_()}},
jt:{"^":"h:2;a,b",
$0:function(){var z=this.a.b
if(!z.gdh())z.f1(this.b)}},
cB:{"^":"ec;b,c,a",
bD:function(a,b){var z,y,x
z=P.at(["command","message","port",this,"msg",b])
y=new H.aI(!0,P.b0(null,P.r)).Y(z)
if(init.globalState.x===!0){init.globalState.Q.toString
self.postMessage(y)}else{x=init.globalState.ch.h(0,this.b)
if(x!=null)x.postMessage(y)}},
B:function(a,b){if(b==null)return!1
return b instanceof H.cB&&J.N(this.b,b.b)&&J.N(this.a,b.a)&&J.N(this.c,b.c)},
gE:function(a){var z,y,x
z=J.cQ(this.b,16)
y=J.cQ(this.a,8)
x=this.c
if(typeof x!=="number")return H.d(x)
return(z^y^x)>>>0}},
bJ:{"^":"e;c_:a<,b,dh:c<",
f7:function(){this.c=!0
this.b=null},
f1:function(a){if(this.c)return
this.b.$1(a)},
$isi6:1},
il:{"^":"e;a,b,c",
au:function(){if(self.setTimeout!=null){if(this.b)throw H.c(new P.t("Timer in event loop cannot be canceled."))
var z=this.c
if(z==null)return;--init.globalState.f.b
self.clearTimeout(z)
this.c=null}else throw H.c(new P.t("Canceling a timer."))},
eW:function(a,b){var z,y
if(a===0)z=self.setTimeout==null||init.globalState.x===!0
else z=!1
if(z){this.c=1
z=init.globalState.f
y=init.globalState.d
z.a.a3(new H.bp(y,new H.io(this,b),"timer"))
this.b=!0}else if(self.setTimeout!=null){++init.globalState.f.b
this.c=self.setTimeout(H.aO(new H.ip(this,b),0),a)}else throw H.c(new P.t("Timer greater than 0."))},
v:{
im:function(a,b){var z=new H.il(!0,!1,null)
z.eW(a,b)
return z}}},
io:{"^":"h:1;a,b",
$0:function(){this.a.c=null
this.b.$0()}},
ip:{"^":"h:1;a,b",
$0:[function(){this.a.c=null;--init.globalState.f.b
this.b.$0()},null,null,0,0,null,"call"]},
aB:{"^":"e;c_:a<",
gE:function(a){var z,y,x
z=this.a
y=J.ae(z)
x=y.ez(z,0)
y=y.bJ(z,4294967296)
if(typeof y!=="number")return H.d(y)
z=x^y
z=(~z>>>0)+(z<<15>>>0)&4294967295
z=((z^z>>>12)>>>0)*5&4294967295
z=((z^z>>>4)>>>0)*2057&4294967295
return(z^z>>>16)>>>0},
B:function(a,b){var z,y
if(b==null)return!1
if(b===this)return!0
if(b instanceof H.aB){z=this.a
y=b.a
return z==null?y==null:z===y}return!1}},
aI:{"^":"e;a,b",
Y:[function(a){var z,y,x,w,v
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
z=this.b
y=z.h(0,a)
if(y!=null)return["ref",y]
z.n(0,a,z.gj(z))
z=J.k(a)
if(!!z.$isds)return["buffer",a]
if(!!z.$isbG)return["typed",a]
if(!!z.$isR)return this.es(a)
if(!!z.$ish6){x=this.gep()
w=a.ga9()
w=H.bD(w,x,H.G(w,"Z",0),null)
w=P.aF(w,!0,H.G(w,"Z",0))
z=z.gcG(a)
z=H.bD(z,x,H.G(z,"Z",0),null)
return["map",w,P.aF(z,!0,H.G(z,"Z",0))]}if(!!z.$ishk)return this.eu(a)
if(!!z.$isi)this.eg(a)
if(!!z.$isi6)this.b6(a,"RawReceivePorts can't be transmitted:")
if(!!z.$isbO)return this.ev(a)
if(!!z.$iscB)return this.ew(a)
if(!!z.$ish){v=a.$static_name
if(v==null)this.b6(a,"Closures can't be transmitted:")
return["function",v]}if(!!z.$isaB)return["capability",a.a]
if(!(a instanceof P.e))this.eg(a)
return["dart",init.classIdExtractor(a),this.er(init.classFieldsExtractor(a))]},"$1","gep",2,0,0,8],
b6:function(a,b){throw H.c(new P.t((b==null?"Can't transmit:":b)+" "+H.b(a)))},
eg:function(a){return this.b6(a,null)},
es:function(a){var z=this.eq(a)
if(!!a.fixed$length)return["fixed",z]
if(!a.fixed$length)return["extendable",z]
if(!a.immutable$list)return["mutable",z]
if(a.constructor===Array)return["const",z]
this.b6(a,"Can't serialize indexable: ")},
eq:function(a){var z,y,x
z=[]
C.a.sj(z,a.length)
for(y=0;y<a.length;++y){x=this.Y(a[y])
if(y>=z.length)return H.a(z,y)
z[y]=x}return z},
er:function(a){var z
for(z=0;z<a.length;++z)C.a.n(a,z,this.Y(a[z]))
return a},
eu:function(a){var z,y,x,w
if(!!a.constructor&&a.constructor!==Object)this.b6(a,"Only plain JS Objects are supported:")
z=Object.keys(a)
y=[]
C.a.sj(y,z.length)
for(x=0;x<z.length;++x){w=this.Y(a[z[x]])
if(x>=y.length)return H.a(y,x)
y[x]=w}return["js-object",z,y]},
ew:function(a){if(this.a)return["sendport",a.b,a.a,a.c]
return["raw sendport",a]},
ev:function(a){if(this.a)return["sendport",init.globalState.b,a.a,a.b.gc_()]
return["raw sendport",a]}},
bM:{"^":"e;a,b",
ai:[function(a){var z,y,x,w,v,u
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
if(typeof a!=="object"||a===null||a.constructor!==Array)throw H.c(P.aR("Bad serialized message: "+H.b(a)))
switch(C.a.ghv(a)){case"ref":if(1>=a.length)return H.a(a,1)
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
y=H.o(this.aO(x),[null])
y.fixed$length=Array
return y
case"extendable":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return H.o(this.aO(x),[null])
case"mutable":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return this.aO(x)
case"const":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
y=H.o(this.aO(x),[null])
y.fixed$length=Array
return y
case"map":return this.hl(a)
case"sendport":return this.hm(a)
case"raw sendport":if(1>=a.length)return H.a(a,1)
x=a[1]
this.b.push(x)
return x
case"js-object":return this.hk(a)
case"function":if(1>=a.length)return H.a(a,1)
x=init.globalFunctions[a[1]]()
this.b.push(x)
return x
case"capability":if(1>=a.length)return H.a(a,1)
return new H.aB(a[1])
case"dart":y=a.length
if(1>=y)return H.a(a,1)
w=a[1]
if(2>=y)return H.a(a,2)
v=a[2]
u=init.instanceFromClassId(w)
this.b.push(u)
this.aO(v)
return init.initializeEmptyInstance(w,u,v)
default:throw H.c("couldn't deserialize: "+H.b(a))}},"$1","ghj",2,0,0,8],
aO:function(a){var z,y,x
z=J.B(a)
y=0
while(!0){x=z.gj(a)
if(typeof x!=="number")return H.d(x)
if(!(y<x))break
z.n(a,y,this.ai(z.h(a,y)));++y}return a},
hl:function(a){var z,y,x,w,v,u
z=a.length
if(1>=z)return H.a(a,1)
y=a[1]
if(2>=z)return H.a(a,2)
x=a[2]
w=P.bC()
this.b.push(w)
y=J.cX(y,this.ghj()).cE(0)
for(z=J.B(y),v=J.B(x),u=0;u<z.gj(y);++u)w.n(0,z.h(y,u),this.ai(v.h(x,u)))
return w},
hm:function(a){var z,y,x,w,v,u,t
z=a.length
if(1>=z)return H.a(a,1)
y=a[1]
if(2>=z)return H.a(a,2)
x=a[2]
if(3>=z)return H.a(a,3)
w=a[3]
if(J.N(y,init.globalState.b)){v=init.globalState.z.h(0,x)
if(v==null)return
u=v.dW(w)
if(u==null)return
t=new H.bO(u,x)}else t=new H.cB(y,w,x)
this.b.push(t)
return t},
hk:function(a){var z,y,x,w,v,u,t
z=a.length
if(1>=z)return H.a(a,1)
y=a[1]
if(2>=z)return H.a(a,2)
x=a[2]
w={}
this.b.push(w)
z=J.B(y)
v=J.B(x)
u=0
while(!0){t=z.gj(y)
if(typeof t!=="number")return H.d(t)
if(!(u<t))break
w[z.h(y,u)]=this.ai(v.h(x,u));++u}return w}}}],["","",,H,{"^":"",
fC:function(){throw H.c(new P.t("Cannot modify unmodifiable Map"))},
kl:function(a){return init.types[a]},
eT:function(a,b){var z
if(b!=null){z=b.x
if(z!=null)return z}return!!J.k(a).$isa_},
b:function(a){var z
if(typeof a==="string")return a
if(typeof a==="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
z=J.A(a)
if(typeof z!=="string")throw H.c(H.I(a))
return z},
al:function(a){var z=a.$identityHash
if(z==null){z=Math.random()*0x3fffffff|0
a.$identityHash=z}return z},
dE:function(a,b){if(b==null)throw H.c(new P.c9(a,null,null))
return b.$1(a)},
dI:function(a,b,c){var z,y
z=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(z==null)return H.dE(a,c)
if(3>=z.length)return H.a(z,3)
y=z[3]
if(y!=null)return parseInt(a,10)
if(z[2]!=null)return parseInt(a,16)
return H.dE(a,c)},
dD:function(a,b){return b.$1(a)},
i4:function(a,b){var z,y
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return H.dD(a,b)
z=parseFloat(a)
if(isNaN(z)){y=C.d.ef(a)
if(y==="NaN"||y==="+NaN"||y==="-NaN")return z
return H.dD(a,b)}return z},
bI:function(a){var z,y,x,w,v,u,t,s
z=J.k(a)
y=z.constructor
if(typeof y=="function"){x=y.name
w=typeof x==="string"?x:null}else w=null
if(w==null||z===C.w||!!J.k(a).$isbn){v=C.o(a)
if(v==="Object"){u=a.constructor
if(typeof u=="function"){t=String(u).match(/^\s*function\s*([\w$]*)\s*\(/)
s=t==null?null:t[1]
if(typeof s==="string"&&/^\w+$/.test(s))w=s}if(w==null)w=v}else w=v}w=w
if(w.length>1&&C.d.aE(w,0)===36)w=C.d.cL(w,1)
return function(b,c){return b.replace(/[^<,> ]+/g,function(d){return c[d]||d})}(w+H.eU(H.bT(a),0,null),init.mangledGlobalNames)},
bH:function(a){return"Instance of '"+H.bI(a)+"'"},
W:function(a){var z
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){z=a-65536
return String.fromCharCode((55296|C.c.c9(z,10))>>>0,56320|z&1023)}throw H.c(P.E(a,0,1114111,null,null))},
P:function(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
i3:function(a){return a.b?H.P(a).getUTCFullYear()+0:H.P(a).getFullYear()+0},
i1:function(a){return a.b?H.P(a).getUTCMonth()+1:H.P(a).getMonth()+1},
hY:function(a){return a.b?H.P(a).getUTCDate()+0:H.P(a).getDate()+0},
hZ:function(a){return a.b?H.P(a).getUTCHours()+0:H.P(a).getHours()+0},
i0:function(a){return a.b?H.P(a).getUTCMinutes()+0:H.P(a).getMinutes()+0},
i2:function(a){return a.b?H.P(a).getUTCSeconds()+0:H.P(a).getSeconds()+0},
i_:function(a){return a.b?H.P(a).getUTCMilliseconds()+0:H.P(a).getMilliseconds()+0},
cq:function(a,b){if(a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string")throw H.c(H.I(a))
return a[b]},
dJ:function(a,b,c){if(a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string")throw H.c(H.I(a))
a[b]=c},
dF:function(a,b,c){var z,y,x
z={}
z.a=0
y=[]
x=[]
z.a=b.length
C.a.P(y,b)
z.b=""
if(c!=null&&!c.gJ(c))c.a0(0,new H.hX(z,y,x))
return J.fb(a,new H.hi(C.J,""+"$"+z.a+z.b,0,y,x,null))},
hW:function(a,b){var z,y
z=b instanceof Array?b:P.aF(b,!0,null)
y=z.length
if(y===0){if(!!a.$0)return a.$0()}else if(y===1){if(!!a.$1)return a.$1(z[0])}else if(y===2){if(!!a.$2)return a.$2(z[0],z[1])}else if(y===3){if(!!a.$3)return a.$3(z[0],z[1],z[2])}else if(y===4){if(!!a.$4)return a.$4(z[0],z[1],z[2],z[3])}else if(y===5)if(!!a.$5)return a.$5(z[0],z[1],z[2],z[3],z[4])
return H.hV(a,z)},
hV:function(a,b){var z,y,x,w,v,u
z=b.length
y=a[""+"$"+z]
if(y==null){y=J.k(a)["call*"]
if(y==null)return H.dF(a,b,null)
x=H.dL(y)
w=x.d
v=w+x.e
if(x.f||w>z||v<z)return H.dF(a,b,null)
b=P.aF(b,!0,null)
for(u=z;u<v;++u)C.a.D(b,init.metadata[x.hg(0,u)])}return y.apply(a,b)},
d:function(a){throw H.c(H.I(a))},
a:function(a,b){if(a==null)J.ag(a)
throw H.c(H.F(a,b))},
F:function(a,b){var z,y
if(typeof b!=="number"||Math.floor(b)!==b)return new P.ao(!0,b,"index",null)
z=J.ag(a)
if(!(b<0)){if(typeof z!=="number")return H.d(z)
y=b>=z}else y=!0
if(y)return P.as(b,a,"index",null,z)
return P.aZ(b,"index",null)},
I:function(a){return new P.ao(!0,a,null,null)},
eN:function(a){if(typeof a!=="number")throw H.c(H.I(a))
return a},
kd:function(a){if(typeof a!=="string")throw H.c(H.I(a))
return a},
c:function(a){var z
if(a==null)a=new P.dB()
z=new Error()
z.dartException=a
if("defineProperty" in Object){Object.defineProperty(z,"message",{get:H.f0})
z.name=""}else z.toString=H.f0
return z},
f0:[function(){return J.A(this.dartException)},null,null,0,0,null],
y:function(a){throw H.c(a)},
z:function(a){throw H.c(new P.ah(a))},
C:function(a){var z,y,x,w,v,u,t,s,r,q,p,o,n,m,l
z=new H.kP(a)
if(a==null)return
if(typeof a!=="object")return a
if("dartException" in a)return z.$1(a.dartException)
else if(!("message" in a))return a
y=a.message
if("number" in a&&typeof a.number=="number"){x=a.number
w=x&65535
if((C.c.c9(x,16)&8191)===10)switch(w){case 438:return z.$1(H.cf(H.b(y)+" (Error "+w+")",null))
case 445:case 5007:v=H.b(y)+" (Error "+w+")"
return z.$1(new H.dA(v,null))}}if(a instanceof TypeError){u=$.$get$dY()
t=$.$get$dZ()
s=$.$get$e_()
r=$.$get$e0()
q=$.$get$e4()
p=$.$get$e5()
o=$.$get$e2()
$.$get$e1()
n=$.$get$e7()
m=$.$get$e6()
l=u.a1(y)
if(l!=null)return z.$1(H.cf(y,l))
else{l=t.a1(y)
if(l!=null){l.method="call"
return z.$1(H.cf(y,l))}else{l=s.a1(y)
if(l==null){l=r.a1(y)
if(l==null){l=q.a1(y)
if(l==null){l=p.a1(y)
if(l==null){l=o.a1(y)
if(l==null){l=r.a1(y)
if(l==null){l=n.a1(y)
if(l==null){l=m.a1(y)
v=l!=null}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0}else v=!0
if(v)return z.$1(new H.dA(y,l==null?null:l.method))}}return z.$1(new H.iA(typeof y==="string"?y:""))}if(a instanceof RangeError){if(typeof y==="string"&&y.indexOf("call stack")!==-1)return new P.dP()
y=function(b){try{return String(b)}catch(k){}return null}(a)
return z.$1(new P.ao(!1,null,null,typeof y==="string"?y.replace(/^RangeError:\s*/,""):y))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof y==="string"&&y==="too much recursion")return new P.dP()
return a},
S:function(a){var z
if(a==null)return new H.er(a,null)
z=a.$cachedTrace
if(z!=null)return z
return a.$cachedTrace=new H.er(a,null)},
kI:function(a){if(a==null||typeof a!='object')return J.T(a)
else return H.al(a)},
kk:function(a,b){var z,y,x,w
z=a.length
for(y=0;y<z;y=w){x=y+1
w=x+1
b.n(0,a[y],a[x])}return b},
ku:[function(a,b,c,d,e,f,g){switch(c){case 0:return H.bq(b,new H.kv(a))
case 1:return H.bq(b,new H.kw(a,d))
case 2:return H.bq(b,new H.kx(a,d,e))
case 3:return H.bq(b,new H.ky(a,d,e,f))
case 4:return H.bq(b,new H.kz(a,d,e,f,g))}throw H.c(P.bz("Unsupported number of arguments for wrapped closure"))},null,null,14,0,null,16,17,18,19,20,21,22],
aO:function(a,b){var z
if(a==null)return
z=a.$identity
if(!!z)return z
z=function(c,d,e,f){return function(g,h,i,j){return f(c,e,d,g,h,i,j)}}(a,b,init.globalState.d,H.ku)
a.$identity=z
return z},
fv:function(a,b,c,d,e,f){var z,y,x,w,v,u,t,s,r,q,p,o,n,m
z=b[0]
y=z.$callName
if(!!J.k(c).$isf){z.$reflectionInfo=c
x=H.dL(z).r}else x=c
w=d?Object.create(new H.id().constructor.prototype):Object.create(new H.c3(null,null,null,null).constructor.prototype)
w.$initialize=w.constructor
if(d)v=function(){this.$initialize()}
else{u=$.a7
$.a7=J.v(u,1)
v=new Function("a,b,c,d"+u,"this.$initialize(a,b,c,d"+u+")")}w.constructor=v
v.prototype=w
if(!d){t=e.length==1&&!0
s=H.d4(a,z,t)
s.$reflectionInfo=c}else{w.$static_name=f
s=z
t=!1}if(typeof x=="number")r=function(g,h){return function(){return g(h)}}(H.kl,x)
else if(typeof x=="function")if(d)r=x
else{q=t?H.d2:H.c4
r=function(g,h){return function(){return g.apply({$receiver:h(this)},arguments)}}(x,q)}else throw H.c("Error in reflectionInfo.")
w.$S=r
w[y]=s
for(u=b.length,p=1;p<u;++p){o=b[p]
n=o.$callName
if(n!=null){m=d?o:H.d4(a,o,t)
w[n]=m}}w["call*"]=s
w.$R=z.$R
w.$D=z.$D
return v},
fs:function(a,b,c,d){var z=H.c4
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,z)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,z)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,z)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,z)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,z)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,z)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,z)}},
d4:function(a,b,c){var z,y,x,w,v,u,t
if(c)return H.fu(a,b)
z=b.$stubName
y=b.length
x=a[z]
w=b==null?x==null:b===x
v=!w||y>=27
if(v)return H.fs(y,!w,z,b)
if(y===0){w=$.a7
$.a7=J.v(w,1)
u="self"+H.b(w)
w="return function(){var "+u+" = this."
v=$.aS
if(v==null){v=H.bw("self")
$.aS=v}return new Function(w+H.b(v)+";return "+u+"."+H.b(z)+"();}")()}t="abcdefghijklmnopqrstuvwxyz".split("").splice(0,y).join(",")
w=$.a7
$.a7=J.v(w,1)
t+=H.b(w)
w="return function("+t+"){return this."
v=$.aS
if(v==null){v=H.bw("self")
$.aS=v}return new Function(w+H.b(v)+"."+H.b(z)+"("+t+");}")()},
ft:function(a,b,c,d){var z,y
z=H.c4
y=H.d2
switch(b?-1:a){case 0:throw H.c(new H.i9("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,z,y)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,z,y)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,z,y)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,z,y)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,z,y)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,z,y)
default:return function(e,f,g,h){return function(){h=[g(this)]
Array.prototype.push.apply(h,arguments)
return e.apply(f(this),h)}}(d,z,y)}},
fu:function(a,b){var z,y,x,w,v,u,t,s
z=H.fq()
y=$.d1
if(y==null){y=H.bw("receiver")
$.d1=y}x=b.$stubName
w=b.length
v=a[x]
u=b==null?v==null:b===v
t=!u||w>=28
if(t)return H.ft(w,!u,x,b)
if(w===1){y="return function(){return this."+H.b(z)+"."+H.b(x)+"(this."+H.b(y)+");"
u=$.a7
$.a7=J.v(u,1)
return new Function(y+H.b(u)+"}")()}s="abcdefghijklmnopqrstuvwxyz".split("").splice(0,w-1).join(",")
y="return function("+s+"){return this."+H.b(z)+"."+H.b(x)+"(this."+H.b(y)+", "+s+");"
u=$.a7
$.a7=J.v(u,1)
return new Function(y+H.b(u)+"}")()},
cI:function(a,b,c,d,e,f){var z
b.fixed$length=Array
if(!!J.k(c).$isf){c.fixed$length=Array
z=c}else z=c
return H.fv(a,b,z,!!d,e,f)},
kG:function(a){if(typeof a==="number"||a==null)return a
throw H.c(H.d3(H.bI(a),"num"))},
kK:function(a,b){var z=J.B(b)
throw H.c(H.d3(H.bI(a),z.ac(b,3,z.gj(b))))},
eR:function(a,b){var z
if(a!=null)z=(typeof a==="object"||typeof a==="function")&&J.k(a)[b]
else z=!0
if(z)return a
H.kK(a,b)},
ki:function(a){var z=J.k(a)
return"$S" in z?z.$S():null},
ay:function(a,b){var z
if(a==null)return!1
z=H.ki(a)
return z==null?!1:H.eS(z,b)},
kO:function(a){throw H.c(new P.fG(a))},
bX:function(){return(Math.random()*0x100000000>>>0)+(Math.random()*0x100000000>>>0)*4294967296},
cK:function(a){return init.getIsolateTag(a)},
o:function(a,b){a.$ti=b
return a},
bT:function(a){if(a==null)return
return a.$ti},
eQ:function(a,b){return H.cO(a["$as"+H.b(b)],H.bT(a))},
G:function(a,b,c){var z=H.eQ(a,b)
return z==null?null:z[c]},
H:function(a,b){var z=H.bT(a)
return z==null?null:z[b]},
aP:function(a,b){var z
if(a==null)return"dynamic"
if(typeof a==="object"&&a!==null&&a.constructor===Array)return a[0].builtin$cls+H.eU(a,1,b)
if(typeof a=="function")return a.builtin$cls
if(typeof a==="number"&&Math.floor(a)===a)return H.b(a)
if(typeof a.func!="undefined"){z=a.typedef
if(z!=null)return H.aP(z,b)
return H.jX(a,b)}return"unknown-reified-type"},
jX:function(a,b){var z,y,x,w,v,u,t,s,r,q,p
z=!!a.v?"void":H.aP(a.ret,b)
if("args" in a){y=a.args
for(x=y.length,w="",v="",u=0;u<x;++u,v=", "){t=y[u]
w=w+v+H.aP(t,b)}}else{w=""
v=""}if("opt" in a){s=a.opt
w+=v+"["
for(x=s.length,v="",u=0;u<x;++u,v=", "){t=s[u]
w=w+v+H.aP(t,b)}w+="]"}if("named" in a){r=a.named
w+=v+"{"
for(x=H.kj(r),q=x.length,v="",u=0;u<q;++u,v=", "){p=x[u]
w=w+v+H.aP(r[p],b)+(" "+H.b(p))}w+="}"}return"("+w+") => "+z},
eU:function(a,b,c){var z,y,x,w,v,u
if(a==null)return""
z=new P.aG("")
for(y=b,x=!0,w=!0,v="";y<a.length;++y){if(x)x=!1
else z.l=v+", "
u=a[y]
if(u!=null)w=!1
v=z.l+=H.aP(u,c)}return w?"":"<"+z.k(0)+">"},
cO:function(a,b){if(a==null)return b
a=a.apply(null,b)
if(a==null)return
if(typeof a==="object"&&a!==null&&a.constructor===Array)return a
if(typeof a=="function")return a.apply(null,b)
return b},
br:function(a,b,c,d){var z,y
if(a==null)return!1
z=H.bT(a)
y=J.k(a)
if(y[b]==null)return!1
return H.eK(H.cO(y[d],z),c)},
eK:function(a,b){var z,y
if(a==null||b==null)return!0
z=a.length
for(y=0;y<z;++y)if(!H.Y(a[y],b[y]))return!1
return!0},
b4:function(a,b,c){return a.apply(b,H.eQ(b,c))},
Y:function(a,b){var z,y,x,w,v,u
if(a===b)return!0
if(a==null||b==null)return!0
if(a.builtin$cls==="aX")return!0
if('func' in b)return H.eS(a,b)
if('func' in a)return b.builtin$cls==="ca"||b.builtin$cls==="e"
z=typeof a==="object"&&a!==null&&a.constructor===Array
y=z?a[0]:a
x=typeof b==="object"&&b!==null&&b.constructor===Array
w=x?b[0]:b
if(w!==y){v=H.aP(w,null)
if(!('$is'+v in y.prototype))return!1
u=y.prototype["$as"+v]}else u=null
if(!z&&u==null||!x)return!0
z=z?a.slice(1):null
x=b.slice(1)
return H.eK(H.cO(u,z),x)},
eJ:function(a,b,c){var z,y,x,w,v
z=b==null
if(z&&a==null)return!0
if(z)return c
if(a==null)return!1
y=a.length
x=b.length
if(c){if(y<x)return!1}else if(y!==x)return!1
for(w=0;w<x;++w){z=a[w]
v=b[w]
if(!(H.Y(z,v)||H.Y(v,z)))return!1}return!0},
k7:function(a,b){var z,y,x,w,v,u
if(b==null)return!0
if(a==null)return!1
z=Object.getOwnPropertyNames(b)
z.fixed$length=Array
y=z
for(z=y.length,x=0;x<z;++x){w=y[x]
if(!Object.hasOwnProperty.call(a,w))return!1
v=b[w]
u=a[w]
if(!(H.Y(v,u)||H.Y(u,v)))return!1}return!0},
eS:function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o,n,m,l
if(!('func' in a))return!1
if("v" in a){if(!("v" in b)&&"ret" in b)return!1}else if(!("v" in b)){z=a.ret
y=b.ret
if(!(H.Y(z,y)||H.Y(y,z)))return!1}x=a.args
w=b.args
v=a.opt
u=b.opt
t=x!=null?x.length:0
s=w!=null?w.length:0
r=v!=null?v.length:0
q=u!=null?u.length:0
if(t>s)return!1
if(t+r<s+q)return!1
if(t===s){if(!H.eJ(x,w,!1))return!1
if(!H.eJ(v,u,!0))return!1}else{for(p=0;p<t;++p){o=x[p]
n=w[p]
if(!(H.Y(o,n)||H.Y(n,o)))return!1}for(m=p,l=0;m<s;++l,++m){o=v[l]
n=w[m]
if(!(H.Y(o,n)||H.Y(n,o)))return!1}for(m=0;m<q;++l,++m){o=v[l]
n=u[m]
if(!(H.Y(o,n)||H.Y(n,o)))return!1}}return H.k7(a.named,b.named)},
mN:function(a){var z=$.cL
return"Instance of "+(z==null?"<Unknown>":z.$1(a))},
mJ:function(a){return H.al(a)},
mI:function(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
kC:function(a){var z,y,x,w,v,u
z=$.cL.$1(a)
y=$.bR[z]
if(y!=null){Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}x=$.bU[z]
if(x!=null)return x
w=init.interceptorsByTag[z]
if(w==null){z=$.eI.$2(a,z)
if(z!=null){y=$.bR[z]
if(y!=null){Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}x=$.bU[z]
if(x!=null)return x
w=init.interceptorsByTag[z]}}if(w==null)return
x=w.prototype
v=z[0]
if(v==="!"){y=H.cN(x)
$.bR[z]=y
Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}if(v==="~"){$.bU[z]=x
return x}if(v==="-"){u=H.cN(x)
Object.defineProperty(Object.getPrototypeOf(a),init.dispatchPropertyName,{value:u,enumerable:false,writable:true,configurable:true})
return u.i}if(v==="+")return H.eW(a,x)
if(v==="*")throw H.c(new P.e8(z))
if(init.leafTags[z]===true){u=H.cN(x)
Object.defineProperty(Object.getPrototypeOf(a),init.dispatchPropertyName,{value:u,enumerable:false,writable:true,configurable:true})
return u.i}else return H.eW(a,x)},
eW:function(a,b){var z=Object.getPrototypeOf(a)
Object.defineProperty(z,init.dispatchPropertyName,{value:J.bV(b,z,null,null),enumerable:false,writable:true,configurable:true})
return b},
cN:function(a){return J.bV(a,!1,null,!!a.$isa_)},
kD:function(a,b,c){var z=b.prototype
if(init.leafTags[a]===true)return J.bV(z,!1,null,!!z.$isa_)
else return J.bV(z,c,null,null)},
ks:function(){if(!0===$.cM)return
$.cM=!0
H.kt()},
kt:function(){var z,y,x,w,v,u,t,s
$.bR=Object.create(null)
$.bU=Object.create(null)
H.ko()
z=init.interceptorsByTag
y=Object.getOwnPropertyNames(z)
if(typeof window!="undefined"){window
x=function(){}
for(w=0;w<y.length;++w){v=y[w]
u=$.eX.$1(v)
if(u!=null){t=H.kD(v,z[v],u)
if(t!=null){Object.defineProperty(u,init.dispatchPropertyName,{value:t,enumerable:false,writable:true,configurable:true})
x.prototype=u}}}}for(w=0;w<y.length;++w){v=y[w]
if(/^[A-Za-z_]/.test(v)){s=z[v]
z["!"+v]=s
z["~"+v]=s
z["-"+v]=s
z["+"+v]=s
z["*"+v]=s}}},
ko:function(){var z,y,x,w,v,u,t
z=C.A()
z=H.aN(C.x,H.aN(C.C,H.aN(C.n,H.aN(C.n,H.aN(C.B,H.aN(C.y,H.aN(C.z(C.o),z)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){y=dartNativeDispatchHooksTransformer
if(typeof y=="function")y=[y]
if(y.constructor==Array)for(x=0;x<y.length;++x){w=y[x]
if(typeof w=="function")z=w(z)||z}}v=z.getTag
u=z.getUnknownTag
t=z.prototypeForTag
$.cL=new H.kp(v)
$.eI=new H.kq(u)
$.eX=new H.kr(t)},
aN:function(a,b){return a(b)||b},
kN:function(a,b,c){var z=a.indexOf(b,c)
return z>=0},
f_:function(a,b,c){var z,y,x
H.kd(c)
if(b==="")if(a==="")return c
else{z=a.length
y=H.b(c)
for(x=0;x<z;++x)y=y+a[x]+H.b(c)
return y.charCodeAt(0)==0?y:y}else return a.replace(new RegExp(b.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&"),'g'),c.replace(/\$/g,"$$$$"))},
fB:{"^":"e9;a,$ti",$ase9:I.K,$asV:I.K,$isV:1},
fA:{"^":"e;",
gJ:function(a){return this.gj(this)===0},
k:function(a){return P.cm(this)},
n:function(a,b,c){return H.fC()},
$isV:1},
fD:{"^":"fA;a,b,c,$ti",
gj:function(a){return this.a},
a_:function(a){if(typeof a!=="string")return!1
if("__proto__"===a)return!1
return this.b.hasOwnProperty(a)},
h:function(a,b){if(!this.a_(b))return
return this.d6(b)},
d6:function(a){return this.b[a]},
a0:function(a,b){var z,y,x,w
z=this.c
for(y=z.length,x=0;x<y;++x){w=z[x]
b.$2(w,this.d6(w))}}},
hi:{"^":"e;a,b,c,d,e,f",
gdX:function(){var z=this.a
return z},
ge4:function(){var z,y,x,w
if(this.c===1)return C.h
z=this.d
y=z.length-this.e.length
if(y===0)return C.h
x=[]
for(w=0;w<y;++w){if(w>=z.length)return H.a(z,w)
x.push(z[w])}x.fixed$length=Array
x.immutable$list=Array
return x},
gdY:function(){var z,y,x,w,v,u,t,s,r
if(this.c!==0)return C.q
z=this.e
y=z.length
x=this.d
w=x.length-y
if(y===0)return C.q
v=P.bm
u=new H.U(0,null,null,null,null,null,0,[v,null])
for(t=0;t<y;++t){if(t>=z.length)return H.a(z,t)
s=z[t]
r=w+t
if(r<0||r>=x.length)return H.a(x,r)
u.n(0,new H.ct(s),x[r])}return new H.fB(u,[v,null])}},
i8:{"^":"e;a,b,c,d,e,f,r,x",
hg:function(a,b){var z=this.d
if(typeof b!=="number")return b.X()
if(b<z)return
return this.b[3+b-z]},
v:{
dL:function(a){var z,y,x
z=a.$reflectionInfo
if(z==null)return
z.fixed$length=Array
z=z
y=z[0]
x=z[1]
return new H.i8(a,z,(y&1)===1,y>>1,x>>1,(x&1)===1,z[2],null)}}},
hX:{"^":"h:8;a,b,c",
$2:function(a,b){var z=this.a
z.b=z.b+"$"+H.b(a)
this.c.push(a)
this.b.push(b);++z.a}},
iy:{"^":"e;a,b,c,d,e,f",
a1:function(a){var z,y,x
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
v:{
aa:function(a){var z,y,x,w,v,u
a=a.replace(String({}),'$receiver$').replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
z=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(z==null)z=[]
y=z.indexOf("\\$arguments\\$")
x=z.indexOf("\\$argumentsExpr\\$")
w=z.indexOf("\\$expr\\$")
v=z.indexOf("\\$method\\$")
u=z.indexOf("\\$receiver\\$")
return new H.iy(a.replace(new RegExp('\\\\\\$arguments\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$argumentsExpr\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$expr\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$method\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$receiver\\\\\\$','g'),'((?:x|[^x])*)'),y,x,w,v,u)},
bK:function(a){return function($expr$){var $argumentsExpr$='$arguments$'
try{$expr$.$method$($argumentsExpr$)}catch(z){return z.message}}(a)},
e3:function(a){return function($expr$){try{$expr$.$method$}catch(z){return z.message}}(a)}}},
dA:{"^":"J;a,b",
k:function(a){var z=this.b
if(z==null)return"NullError: "+H.b(this.a)
return"NullError: method not found: '"+H.b(z)+"' on null"}},
hr:{"^":"J;a,b,c",
k:function(a){var z,y
z=this.b
if(z==null)return"NoSuchMethodError: "+H.b(this.a)
y=this.c
if(y==null)return"NoSuchMethodError: method not found: '"+z+"' ("+H.b(this.a)+")"
return"NoSuchMethodError: method not found: '"+z+"' on '"+y+"' ("+H.b(this.a)+")"},
v:{
cf:function(a,b){var z,y
z=b==null
y=z?null:b.method
return new H.hr(a,y,z?null:b.receiver)}}},
iA:{"^":"J;a",
k:function(a){var z=this.a
return z.length===0?"Error":"Error: "+z}},
kP:{"^":"h:0;a",
$1:function(a){if(!!J.k(a).$isJ)if(a.$thrownJsError==null)a.$thrownJsError=this.a
return a}},
er:{"^":"e;a,b",
k:function(a){var z,y
z=this.b
if(z!=null)return z
z=this.a
y=z!==null&&typeof z==="object"?z.stack:null
z=y==null?"":y
this.b=z
return z}},
kv:{"^":"h:2;a",
$0:function(){return this.a.$0()}},
kw:{"^":"h:2;a,b",
$0:function(){return this.a.$1(this.b)}},
kx:{"^":"h:2;a,b,c",
$0:function(){return this.a.$2(this.b,this.c)}},
ky:{"^":"h:2;a,b,c,d",
$0:function(){return this.a.$3(this.b,this.c,this.d)}},
kz:{"^":"h:2;a,b,c,d,e",
$0:function(){return this.a.$4(this.b,this.c,this.d,this.e)}},
h:{"^":"e;",
k:function(a){return"Closure '"+H.bI(this).trim()+"'"},
gel:function(){return this},
$isca:1,
gel:function(){return this}},
dT:{"^":"h;"},
id:{"^":"dT;",
k:function(a){var z=this.$static_name
if(z==null)return"Closure of unknown static method"
return"Closure '"+z+"'"}},
c3:{"^":"dT;a,b,c,d",
B:function(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof H.c3))return!1
return this.a===b.a&&this.b===b.b&&this.c===b.c},
gE:function(a){var z,y
z=this.c
if(z==null)y=H.al(this.a)
else y=typeof z!=="object"?J.T(z):H.al(z)
return J.f1(y,H.al(this.b))},
k:function(a){var z=this.c
if(z==null)z=this.a
return"Closure '"+H.b(this.d)+"' of "+H.bH(z)},
v:{
c4:function(a){return a.a},
d2:function(a){return a.c},
fq:function(){var z=$.aS
if(z==null){z=H.bw("self")
$.aS=z}return z},
bw:function(a){var z,y,x,w,v
z=new H.c3("self","target","receiver","name")
y=Object.getOwnPropertyNames(z)
y.fixed$length=Array
x=y
for(y=x.length,w=0;w<y;++w){v=x[w]
if(z[v]===a)return v}}}},
fr:{"^":"J;a",
k:function(a){return this.a},
v:{
d3:function(a,b){return new H.fr("CastError: Casting value of type '"+a+"' to incompatible type '"+b+"'")}}},
i9:{"^":"J;a",
k:function(a){return"RuntimeError: "+H.b(this.a)}},
U:{"^":"e;a,b,c,d,e,f,r,$ti",
gj:function(a){return this.a},
gJ:function(a){return this.a===0},
ga9:function(){return new H.hy(this,[H.H(this,0)])},
gcG:function(a){return H.bD(this.ga9(),new H.hq(this),H.H(this,0),H.H(this,1))},
a_:function(a){var z,y
if(typeof a==="string"){z=this.b
if(z==null)return!1
return this.d3(z,a)}else if(typeof a==="number"&&(a&0x3ffffff)===a){y=this.c
if(y==null)return!1
return this.d3(y,a)}else return this.hI(a)},
hI:function(a){var z=this.d
if(z==null)return!1
return this.aT(this.bh(z,this.aS(a)),a)>=0},
h:function(a,b){var z,y,x
if(typeof b==="string"){z=this.b
if(z==null)return
y=this.aI(z,b)
return y==null?null:y.gal()}else if(typeof b==="number"&&(b&0x3ffffff)===b){x=this.c
if(x==null)return
y=this.aI(x,b)
return y==null?null:y.gal()}else return this.hJ(b)},
hJ:function(a){var z,y,x
z=this.d
if(z==null)return
y=this.bh(z,this.aS(a))
x=this.aT(y,a)
if(x<0)return
return y[x].gal()},
n:function(a,b,c){var z,y,x,w,v,u
if(typeof b==="string"){z=this.b
if(z==null){z=this.c1()
this.b=z}this.cS(z,b,c)}else if(typeof b==="number"&&(b&0x3ffffff)===b){y=this.c
if(y==null){y=this.c1()
this.c=y}this.cS(y,b,c)}else{x=this.d
if(x==null){x=this.c1()
this.d=x}w=this.aS(b)
v=this.bh(x,w)
if(v==null)this.c8(x,w,[this.c2(b,c)])
else{u=this.aT(v,b)
if(u>=0)v[u].sal(c)
else v.push(this.c2(b,c))}}},
H:function(a,b){if(typeof b==="string")return this.dm(this.b,b)
else if(typeof b==="number"&&(b&0x3ffffff)===b)return this.dm(this.c,b)
else return this.hK(b)},
hK:function(a){var z,y,x,w
z=this.d
if(z==null)return
y=this.bh(z,this.aS(a))
x=this.aT(y,a)
if(x<0)return
w=y.splice(x,1)[0]
this.dw(w)
return w.gal()},
ah:function(a){if(this.a>0){this.f=null
this.e=null
this.d=null
this.c=null
this.b=null
this.a=0
this.r=this.r+1&67108863}},
a0:function(a,b){var z,y
z=this.e
y=this.r
for(;z!=null;){b.$2(z.a,z.b)
if(y!==this.r)throw H.c(new P.ah(this))
z=z.c}},
cS:function(a,b,c){var z=this.aI(a,b)
if(z==null)this.c8(a,b,this.c2(b,c))
else z.sal(c)},
dm:function(a,b){var z
if(a==null)return
z=this.aI(a,b)
if(z==null)return
this.dw(z)
this.d4(a,b)
return z.gal()},
c2:function(a,b){var z,y
z=new H.hx(a,b,null,null)
if(this.e==null){this.f=z
this.e=z}else{y=this.f
z.d=y
y.c=z
this.f=z}++this.a
this.r=this.r+1&67108863
return z},
dw:function(a){var z,y
z=a.gfz()
y=a.gfv()
if(z==null)this.e=y
else z.c=y
if(y==null)this.f=z
else y.d=z;--this.a
this.r=this.r+1&67108863},
aS:function(a){return J.T(a)&0x3ffffff},
aT:function(a,b){var z,y
if(a==null)return-1
z=a.length
for(y=0;y<z;++y)if(J.N(a[y].gdQ(),b))return y
return-1},
k:function(a){return P.cm(this)},
aI:function(a,b){return a[b]},
bh:function(a,b){return a[b]},
c8:function(a,b,c){a[b]=c},
d4:function(a,b){delete a[b]},
d3:function(a,b){return this.aI(a,b)!=null},
c1:function(){var z=Object.create(null)
this.c8(z,"<non-identifier-key>",z)
this.d4(z,"<non-identifier-key>")
return z},
$ish6:1,
$isV:1},
hq:{"^":"h:0;a",
$1:[function(a){return this.a.h(0,a)},null,null,2,0,null,23,"call"]},
hx:{"^":"e;dQ:a<,al:b@,fv:c<,fz:d<"},
hy:{"^":"j;a,$ti",
gj:function(a){return this.a.a},
gK:function(a){var z,y
z=this.a
y=new H.hz(z,z.r,null,null)
y.c=z.e
return y}},
hz:{"^":"e;a,b,c,d",
gw:function(){return this.d},
u:function(){var z=this.a
if(this.b!==z.r)throw H.c(new P.ah(z))
else{z=this.c
if(z==null){this.d=null
return!1}else{this.d=z.a
this.c=z.c
return!0}}}},
kp:{"^":"h:0;a",
$1:function(a){return this.a(a)}},
kq:{"^":"h:9;a",
$2:function(a,b){return this.a(a,b)}},
kr:{"^":"h:10;a",
$1:function(a){return this.a(a)}},
ij:{"^":"e;a,b,c",
h:function(a,b){if(b!==0)H.y(P.aZ(b,null,null))
return this.c}}}],["","",,H,{"^":"",
kj:function(a){var z=H.o(a?Object.keys(a):[],[null])
z.fixed$length=Array
return z}}],["","",,H,{"^":"",
kJ:function(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof window=="object")return
if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)}}],["","",,H,{"^":"",ds:{"^":"i;",$isds:1,"%":"ArrayBuffer"},bG:{"^":"i;",
fo:function(a,b,c,d){var z=P.E(b,0,c,d,null)
throw H.c(z)},
cW:function(a,b,c,d){if(b>>>0!==b||b>c)this.fo(a,b,c,d)},
$isbG:1,
$isa1:1,
"%":";ArrayBufferView;cn|dt|dv|bF|du|dw|aj"},lL:{"^":"bG;",$isa1:1,"%":"DataView"},cn:{"^":"bG;",
gj:function(a){return a.length},
dt:function(a,b,c,d,e){var z,y,x
z=a.length
this.cW(a,b,z,"start")
this.cW(a,c,z,"end")
if(b>c)throw H.c(P.E(b,0,c,null,null))
y=c-b
x=d.length
if(x-e<y)throw H.c(new P.X("Not enough elements"))
if(e!==0||x!==y)d=d.subarray(e,e+y)
a.set(d,b)},
$isa_:1,
$asa_:I.K,
$isR:1,
$asR:I.K},bF:{"^":"dv;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
return a[b]},
n:function(a,b,c){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
a[b]=c},
a2:function(a,b,c,d,e){if(!!J.k(d).$isbF){this.dt(a,b,c,d,e)
return}this.cN(a,b,c,d,e)}},dt:{"^":"cn+a0;",$asa_:I.K,$asR:I.K,
$asf:function(){return[P.ad]},
$asj:function(){return[P.ad]},
$isf:1,
$isj:1},dv:{"^":"dt+di;",$asa_:I.K,$asR:I.K,
$asf:function(){return[P.ad]},
$asj:function(){return[P.ad]}},aj:{"^":"dw;",
n:function(a,b,c){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
a[b]=c},
a2:function(a,b,c,d,e){if(!!J.k(d).$isaj){this.dt(a,b,c,d,e)
return}this.cN(a,b,c,d,e)},
$isf:1,
$asf:function(){return[P.r]},
$isj:1,
$asj:function(){return[P.r]}},du:{"^":"cn+a0;",$asa_:I.K,$asR:I.K,
$asf:function(){return[P.r]},
$asj:function(){return[P.r]},
$isf:1,
$isj:1},dw:{"^":"du+di;",$asa_:I.K,$asR:I.K,
$asf:function(){return[P.r]},
$asj:function(){return[P.r]}},lM:{"^":"bF;",$isa1:1,$isf:1,
$asf:function(){return[P.ad]},
$isj:1,
$asj:function(){return[P.ad]},
"%":"Float32Array"},lN:{"^":"bF;",$isa1:1,$isf:1,
$asf:function(){return[P.ad]},
$isj:1,
$asj:function(){return[P.ad]},
"%":"Float64Array"},lO:{"^":"aj;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
return a[b]},
$isa1:1,
$isf:1,
$asf:function(){return[P.r]},
$isj:1,
$asj:function(){return[P.r]},
"%":"Int16Array"},lP:{"^":"aj;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
return a[b]},
$isa1:1,
$isf:1,
$asf:function(){return[P.r]},
$isj:1,
$asj:function(){return[P.r]},
"%":"Int32Array"},lQ:{"^":"aj;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
return a[b]},
$isa1:1,
$isf:1,
$asf:function(){return[P.r]},
$isj:1,
$asj:function(){return[P.r]},
"%":"Int8Array"},lR:{"^":"aj;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
return a[b]},
$isa1:1,
$isf:1,
$asf:function(){return[P.r]},
$isj:1,
$asj:function(){return[P.r]},
"%":"Uint16Array"},lS:{"^":"aj;",
h:function(a,b){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
return a[b]},
$isa1:1,
$isf:1,
$asf:function(){return[P.r]},
$isj:1,
$asj:function(){return[P.r]},
"%":"Uint32Array"},lT:{"^":"aj;",
gj:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
return a[b]},
$isa1:1,
$isf:1,
$asf:function(){return[P.r]},
$isj:1,
$asj:function(){return[P.r]},
"%":"CanvasPixelArray|Uint8ClampedArray"},lU:{"^":"aj;",
gj:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)H.y(H.F(a,b))
return a[b]},
$isa1:1,
$isf:1,
$asf:function(){return[P.r]},
$isj:1,
$asj:function(){return[P.r]},
"%":";Uint8Array"}}],["","",,P,{"^":"",
iE:function(){var z,y,x
z={}
if(self.scheduleImmediate!=null)return P.k8()
if(self.MutationObserver!=null&&self.document!=null){y=self.document.createElement("div")
x=self.document.createElement("span")
z.a=null
new self.MutationObserver(H.aO(new P.iG(z),1)).observe(y,{childList:true})
return new P.iF(z,y,x)}else if(self.setImmediate!=null)return P.k9()
return P.ka()},
mo:[function(a){++init.globalState.f.b
self.scheduleImmediate(H.aO(new P.iH(a),0))},"$1","k8",2,0,4],
mp:[function(a){++init.globalState.f.b
self.setImmediate(H.aO(new P.iI(a),0))},"$1","k9",2,0,4],
mq:[function(a){P.cu(C.m,a)},"$1","ka",2,0,4],
jY:function(a,b,c){if(H.ay(a,{func:1,args:[P.aX,P.aX]}))return a.$2(b,c)
else return a.$1(b)},
eA:function(a,b){if(H.ay(a,{func:1,args:[P.aX,P.aX]})){b.toString
return a}else{b.toString
return a}},
k_:function(){var z,y
for(;z=$.aJ,z!=null;){$.b2=null
y=z.gR()
$.aJ=y
if(y==null)$.b1=null
z.gdF().$0()}},
mH:[function(){$.cF=!0
try{P.k_()}finally{$.b2=null
$.cF=!1
if($.aJ!=null)$.$get$cv().$1(P.eM())}},"$0","eM",0,0,1],
eF:function(a){var z=new P.eb(a,null)
if($.aJ==null){$.b1=z
$.aJ=z
if(!$.cF)$.$get$cv().$1(P.eM())}else{$.b1.b=z
$.b1=z}},
k3:function(a){var z,y,x
z=$.aJ
if(z==null){P.eF(a)
$.b2=$.b1
return}y=new P.eb(a,null)
x=$.b2
if(x==null){y.b=z
$.b2=y
$.aJ=y}else{y.b=x.b
x.b=y
$.b2=y
if(y.b==null)$.b1=y}},
eY:function(a){var z=$.q
if(C.b===z){P.aL(null,null,C.b,a)
return}z.toString
P.aL(null,null,z,z.cc(a,!0))},
eE:function(a){var z,y,x,w
if(a==null)return
try{a.$0()}catch(x){z=H.C(x)
y=H.S(x)
w=$.q
w.toString
P.aK(null,null,w,z,y)}},
mF:[function(a){},"$1","kb",2,0,16,2],
k0:[function(a,b){var z=$.q
z.toString
P.aK(null,null,z,a,b)},function(a){return P.k0(a,null)},"$2","$1","kc",2,2,3,0],
mG:[function(){},"$0","eL",0,0,1],
eu:function(a,b,c){$.q.toString
a.ap(b,c)},
iq:function(a,b){var z=$.q
if(z===C.b){z.toString
return P.cu(a,b)}return P.cu(a,z.cc(b,!0))},
cu:function(a,b){var z=C.c.bq(a.a,1000)
return H.im(z<0?0:z,b)},
iD:function(){return $.q},
aK:function(a,b,c,d,e){var z={}
z.a=d
P.k3(new P.k2(z,e))},
eB:function(a,b,c,d){var z,y
y=$.q
if(y===c)return d.$0()
$.q=c
z=y
try{y=d.$0()
return y}finally{$.q=z}},
eD:function(a,b,c,d,e){var z,y
y=$.q
if(y===c)return d.$1(e)
$.q=c
z=y
try{y=d.$1(e)
return y}finally{$.q=z}},
eC:function(a,b,c,d,e,f){var z,y
y=$.q
if(y===c)return d.$2(e,f)
$.q=c
z=y
try{y=d.$2(e,f)
return y}finally{$.q=z}},
aL:function(a,b,c,d){var z=C.b!==c
if(z)d=c.cc(d,!(!z||!1))
P.eF(d)},
iG:{"^":"h:0;a",
$1:[function(a){var z,y;--init.globalState.f.b
z=this.a
y=z.a
z.a=null
y.$0()},null,null,2,0,null,3,"call"]},
iF:{"^":"h:11;a,b,c",
$1:function(a){var z,y;++init.globalState.f.b
this.a.a=a
z=this.b
y=this.c
z.firstChild?z.removeChild(y):z.appendChild(y)}},
iH:{"^":"h:2;a",
$0:[function(){--init.globalState.f.b
this.a.$0()},null,null,0,0,null,"call"]},
iI:{"^":"h:2;a",
$0:[function(){--init.globalState.f.b
this.a.$0()},null,null,0,0,null,"call"]},
iK:{"^":"ed;a,$ti"},
iL:{"^":"iP;aF:y@,a6:z@,ba:Q@,x,a,b,c,d,e,f,r,$ti",
fh:function(a){return(this.y&1)===a},
fW:function(){this.y^=1},
gfq:function(){return(this.y&2)!==0},
fQ:function(){this.y|=4},
gfF:function(){return(this.y&4)!==0},
bj:[function(){},"$0","gbi",0,0,1],
bl:[function(){},"$0","gbk",0,0,1]},
cw:{"^":"e;a5:c<,$ti",
gaU:function(){return!1},
gaJ:function(){return this.c<4},
ff:function(){var z=this.r
if(z!=null)return z
z=new P.ac(0,$.q,null,[null])
this.r=z
return z},
aC:function(a){var z
a.saF(this.c&1)
z=this.e
this.e=a
a.sa6(null)
a.sba(z)
if(z==null)this.d=a
else z.sa6(a)},
dn:function(a){var z,y
z=a.gba()
y=a.ga6()
if(z==null)this.d=y
else z.sa6(y)
if(y==null)this.e=z
else y.sba(z)
a.sba(a)
a.sa6(a)},
fV:function(a,b,c,d){var z,y,x
if((this.c&4)!==0){if(c==null)c=P.eL()
z=new P.iV($.q,0,c,this.$ti)
z.ds()
return z}z=$.q
y=d?1:0
x=new P.iL(0,null,null,this,null,null,null,z,y,null,null,this.$ti)
x.cQ(a,b,c,d,H.H(this,0))
x.Q=x
x.z=x
this.aC(x)
z=this.d
y=this.e
if(z==null?y==null:z===y)P.eE(this.a)
return x},
fB:function(a){if(a.ga6()===a)return
if(a.gfq())a.fQ()
else{this.dn(a)
if((this.c&2)===0&&this.d==null)this.bM()}return},
fC:function(a){},
fD:function(a){},
b9:["eL",function(){if((this.c&4)!==0)return new P.X("Cannot add new events after calling close")
return new P.X("Cannot add new events while doing an addStream")}],
D:[function(a,b){if(!this.gaJ())throw H.c(this.b9())
this.bo(b)},"$1","gfZ",2,0,function(){return H.b4(function(a){return{func:1,v:true,args:[a]}},this.$receiver,"cw")}],
h1:[function(a,b){if(!this.gaJ())throw H.c(this.b9())
$.q.toString
this.bp(a,b)},function(a){return this.h1(a,null)},"ih","$2","$1","gh0",2,2,3,0],
dI:function(a){var z
if((this.c&4)!==0)return this.r
if(!this.gaJ())throw H.c(this.b9())
this.c|=4
z=this.ff()
this.aL()
return z},
bZ:function(a){var z,y,x,w
z=this.c
if((z&2)!==0)throw H.c(new P.X("Cannot fire new event. Controller is already firing an event"))
y=this.d
if(y==null)return
x=z&1
this.c=z^3
for(;y!=null;)if(y.fh(x)){y.saF(y.gaF()|2)
a.$1(y)
y.fW()
w=y.ga6()
if(y.gfF())this.dn(y)
y.saF(y.gaF()&4294967293)
y=w}else y=y.ga6()
this.c&=4294967293
if(this.d==null)this.bM()},
bM:function(){if((this.c&4)!==0&&this.r.a===0)this.r.cV(null)
P.eE(this.b)}},
bP:{"^":"cw;a,b,c,d,e,f,r,$ti",
gaJ:function(){return P.cw.prototype.gaJ.call(this)===!0&&(this.c&2)===0},
b9:function(){if((this.c&2)!==0)return new P.X("Cannot fire new event. Controller is already firing an event")
return this.eL()},
bo:function(a){var z=this.d
if(z==null)return
if(z===this.e){this.c|=2
z.aD(a)
this.c&=4294967293
if(this.d==null)this.bM()
return}this.bZ(new P.jK(this,a))},
bp:function(a,b){if(this.d==null)return
this.bZ(new P.jM(this,a,b))},
aL:function(){if(this.d!=null)this.bZ(new P.jL(this))
else this.r.cV(null)}},
jK:{"^":"h;a,b",
$1:function(a){a.aD(this.b)},
$S:function(){return H.b4(function(a){return{func:1,args:[[P.av,a]]}},this.a,"bP")}},
jM:{"^":"h;a,b,c",
$1:function(a){a.ap(this.b,this.c)},
$S:function(){return H.b4(function(a){return{func:1,args:[[P.av,a]]}},this.a,"bP")}},
jL:{"^":"h;a",
$1:function(a){a.cU()},
$S:function(){return H.b4(function(a){return{func:1,args:[[P.av,a]]}},this.a,"bP")}},
iO:{"^":"e;$ti"},
jN:{"^":"iO;a,$ti"},
ej:{"^":"e;a7:a@,I:b>,c,dF:d<,e",
gaf:function(){return this.b.b},
gdO:function(){return(this.c&1)!==0},
ghD:function(){return(this.c&2)!==0},
gdN:function(){return this.c===8},
ghE:function(){return this.e!=null},
hB:function(a){return this.b.b.cz(this.d,a)},
hS:function(a){if(this.c!==6)return!0
return this.b.b.cz(this.d,J.b7(a))},
dM:function(a){var z,y,x
z=this.e
y=J.m(a)
x=this.b.b
if(H.ay(z,{func:1,args:[,,]}))return x.i2(z,y.gaj(a),a.gab())
else return x.cz(z,y.gaj(a))},
hC:function(){return this.b.b.e9(this.d)}},
ac:{"^":"e;a5:a<,af:b<,ar:c<,$ti",
gfp:function(){return this.a===2},
gc0:function(){return this.a>=4},
gfm:function(){return this.a===8},
fN:function(a){this.a=2
this.c=a},
ed:function(a,b){var z,y
z=$.q
if(z!==C.b){z.toString
if(b!=null)b=P.eA(b,z)}y=new P.ac(0,$.q,null,[null])
this.aC(new P.ej(null,y,b==null?1:3,a,b))
return y},
ec:function(a){return this.ed(a,null)},
ei:function(a){var z,y
z=$.q
y=new P.ac(0,z,null,this.$ti)
if(z!==C.b)z.toString
this.aC(new P.ej(null,y,8,a,null))
return y},
fP:function(){this.a=1},
f6:function(){this.a=0},
gad:function(){return this.c},
gf4:function(){return this.c},
fR:function(a){this.a=4
this.c=a},
fO:function(a){this.a=8
this.c=a},
cX:function(a){this.a=a.ga5()
this.c=a.gar()},
aC:function(a){var z,y
z=this.a
if(z<=1){a.a=this.c
this.c=a}else{if(z===2){y=this.c
if(!y.gc0()){y.aC(a)
return}this.a=y.ga5()
this.c=y.gar()}z=this.b
z.toString
P.aL(null,null,z,new P.j2(this,a))}},
dl:function(a){var z,y,x,w,v
z={}
z.a=a
if(a==null)return
y=this.a
if(y<=1){x=this.c
this.c=a
if(x!=null){for(w=a;w.ga7()!=null;)w=w.ga7()
w.sa7(x)}}else{if(y===2){v=this.c
if(!v.gc0()){v.dl(a)
return}this.a=v.ga5()
this.c=v.gar()}z.a=this.dq(a)
y=this.b
y.toString
P.aL(null,null,y,new P.j8(z,this))}},
aq:function(){var z=this.c
this.c=null
return this.dq(z)},
dq:function(a){var z,y,x
for(z=a,y=null;z!=null;y=z,z=x){x=z.ga7()
z.sa7(y)}return y},
bc:function(a){var z,y
z=this.$ti
if(H.br(a,"$isar",z,"$asar"))if(H.br(a,"$isac",z,null))P.bN(a,this)
else P.ek(a,this)
else{y=this.aq()
this.a=4
this.c=a
P.aH(this,y)}},
bR:[function(a,b){var z=this.aq()
this.a=8
this.c=new P.bu(a,b)
P.aH(this,z)},function(a){return this.bR(a,null)},"ib","$2","$1","gd2",2,2,3,0,4,5],
cV:function(a){var z
if(H.br(a,"$isar",this.$ti,"$asar")){this.f3(a)
return}this.a=1
z=this.b
z.toString
P.aL(null,null,z,new P.j3(this,a))},
f3:function(a){var z
if(H.br(a,"$isac",this.$ti,null)){if(a.a===8){this.a=1
z=this.b
z.toString
P.aL(null,null,z,new P.j7(this,a))}else P.bN(a,this)
return}P.ek(a,this)},
eZ:function(a,b){this.a=4
this.c=a},
$isar:1,
v:{
ek:function(a,b){var z,y,x
b.fP()
try{a.ed(new P.j4(b),new P.j5(b))}catch(x){z=H.C(x)
y=H.S(x)
P.eY(new P.j6(b,z,y))}},
bN:function(a,b){var z
for(;a.gfp();)a=a.gf4()
if(a.gc0()){z=b.aq()
b.cX(a)
P.aH(b,z)}else{z=b.gar()
b.fN(a)
a.dl(z)}},
aH:function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o
z={}
z.a=a
for(y=a;!0;){x={}
w=y.gfm()
if(b==null){if(w){v=z.a.gad()
y=z.a.gaf()
u=J.b7(v)
t=v.gab()
y.toString
P.aK(null,null,y,u,t)}return}for(;b.ga7()!=null;b=s){s=b.ga7()
b.sa7(null)
P.aH(z.a,b)}r=z.a.gar()
x.a=w
x.b=r
y=!w
if(!y||b.gdO()||b.gdN()){q=b.gaf()
if(w){u=z.a.gaf()
u.toString
u=u==null?q==null:u===q
if(!u)q.toString
else u=!0
u=!u}else u=!1
if(u){v=z.a.gad()
y=z.a.gaf()
u=J.b7(v)
t=v.gab()
y.toString
P.aK(null,null,y,u,t)
return}p=$.q
if(p==null?q!=null:p!==q)$.q=q
else p=null
if(b.gdN())new P.jb(z,x,w,b).$0()
else if(y){if(b.gdO())new P.ja(x,b,r).$0()}else if(b.ghD())new P.j9(z,x,b).$0()
if(p!=null)$.q=p
y=x.b
if(!!J.k(y).$isar){o=J.cU(b)
if(y.a>=4){b=o.aq()
o.cX(y)
z.a=y
continue}else P.bN(y,o)
return}}o=J.cU(b)
b=o.aq()
y=x.a
u=x.b
if(!y)o.fR(u)
else o.fO(u)
z.a=o
y=o}}}},
j2:{"^":"h:2;a,b",
$0:function(){P.aH(this.a,this.b)}},
j8:{"^":"h:2;a,b",
$0:function(){P.aH(this.b,this.a.a)}},
j4:{"^":"h:0;a",
$1:[function(a){var z=this.a
z.f6()
z.bc(a)},null,null,2,0,null,2,"call"]},
j5:{"^":"h:12;a",
$2:[function(a,b){this.a.bR(a,b)},function(a){return this.$2(a,null)},"$1",null,null,null,2,2,null,0,4,5,"call"]},
j6:{"^":"h:2;a,b,c",
$0:function(){this.a.bR(this.b,this.c)}},
j3:{"^":"h:2;a,b",
$0:function(){var z,y
z=this.a
y=z.aq()
z.a=4
z.c=this.b
P.aH(z,y)}},
j7:{"^":"h:2;a,b",
$0:function(){P.bN(this.b,this.a)}},
jb:{"^":"h:1;a,b,c,d",
$0:function(){var z,y,x,w,v,u,t
z=null
try{z=this.d.hC()}catch(w){y=H.C(w)
x=H.S(w)
if(this.c){v=J.b7(this.a.a.gad())
u=y
u=v==null?u==null:v===u
v=u}else v=!1
u=this.b
if(v)u.b=this.a.a.gad()
else u.b=new P.bu(y,x)
u.a=!0
return}if(!!J.k(z).$isar){if(z instanceof P.ac&&z.ga5()>=4){if(z.ga5()===8){v=this.b
v.b=z.gar()
v.a=!0}return}t=this.a.a
v=this.b
v.b=z.ec(new P.jc(t))
v.a=!1}}},
jc:{"^":"h:0;a",
$1:[function(a){return this.a},null,null,2,0,null,3,"call"]},
ja:{"^":"h:1;a,b,c",
$0:function(){var z,y,x,w
try{this.a.b=this.b.hB(this.c)}catch(x){z=H.C(x)
y=H.S(x)
w=this.a
w.b=new P.bu(z,y)
w.a=!0}}},
j9:{"^":"h:1;a,b,c",
$0:function(){var z,y,x,w,v,u,t,s
try{z=this.a.a.gad()
w=this.c
if(w.hS(z)===!0&&w.ghE()){v=this.b
v.b=w.dM(z)
v.a=!1}}catch(u){y=H.C(u)
x=H.S(u)
w=this.a
v=J.b7(w.a.gad())
t=y
s=this.b
if(v==null?t==null:v===t)s.b=w.a.gad()
else s.b=new P.bu(y,x)
s.a=!0}}},
eb:{"^":"e;dF:a<,R:b@"},
a3:{"^":"e;$ti",
am:function(a,b){return new P.js(b,this,[H.G(this,"a3",0),null])},
hx:function(a,b){return new P.jd(a,b,this,[H.G(this,"a3",0)])},
dM:function(a){return this.hx(a,null)},
gj:function(a){var z,y
z={}
y=new P.ac(0,$.q,null,[P.r])
z.a=0
this.U(new P.ie(z),!0,new P.ig(z,y),y.gd2())
return y},
cE:function(a){var z,y,x
z=H.G(this,"a3",0)
y=H.o([],[z])
x=new P.ac(0,$.q,null,[[P.f,z]])
this.U(new P.ih(this,y),!0,new P.ii(y,x),x.gd2())
return x}},
ie:{"^":"h:0;a",
$1:[function(a){++this.a.a},null,null,2,0,null,3,"call"]},
ig:{"^":"h:2;a,b",
$0:[function(){this.b.bc(this.a.a)},null,null,0,0,null,"call"]},
ih:{"^":"h;a,b",
$1:[function(a){this.b.push(a)},null,null,2,0,null,9,"call"],
$S:function(){return H.b4(function(a){return{func:1,args:[a]}},this.a,"a3")}},
ii:{"^":"h:2;a,b",
$0:[function(){this.b.bc(this.a)},null,null,0,0,null,"call"]},
dQ:{"^":"e;$ti"},
ed:{"^":"jF;a,$ti",
gE:function(a){return(H.al(this.a)^892482866)>>>0},
B:function(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof P.ed))return!1
return b.a===this.a}},
iP:{"^":"av;$ti",
c3:function(){return this.x.fB(this)},
bj:[function(){this.x.fC(this)},"$0","gbi",0,0,1],
bl:[function(){this.x.fD(this)},"$0","gbk",0,0,1]},
av:{"^":"e;af:d<,a5:e<,$ti",
aY:function(a,b){var z=this.e
if((z&8)!==0)return
this.e=(z+128|4)>>>0
if(z<128&&this.r!=null)this.r.dG()
if((z&4)===0&&(this.e&32)===0)this.dd(this.gbi())},
cr:function(a){return this.aY(a,null)},
cu:function(){var z=this.e
if((z&8)!==0)return
if(z>=128){z-=128
this.e=z
if(z<128){if((z&64)!==0){z=this.r
z=!z.gJ(z)}else z=!1
if(z)this.r.bC(this)
else{z=(this.e&4294967291)>>>0
this.e=z
if((z&32)===0)this.dd(this.gbk())}}}},
au:function(){var z=(this.e&4294967279)>>>0
this.e=z
if((z&8)===0)this.bN()
z=this.f
return z==null?$.$get$be():z},
gaU:function(){return this.e>=128},
bN:function(){var z=(this.e|8)>>>0
this.e=z
if((z&64)!==0)this.r.dG()
if((this.e&32)===0)this.r=null
this.f=this.c3()},
aD:["eM",function(a){var z=this.e
if((z&8)!==0)return
if(z<32)this.bo(a)
else this.bL(new P.iS(a,null,[H.G(this,"av",0)]))}],
ap:["eN",function(a,b){var z=this.e
if((z&8)!==0)return
if(z<32)this.bp(a,b)
else this.bL(new P.iU(a,b,null))}],
cU:function(){var z=this.e
if((z&8)!==0)return
z=(z|2)>>>0
this.e=z
if(z<32)this.aL()
else this.bL(C.v)},
bj:[function(){},"$0","gbi",0,0,1],
bl:[function(){},"$0","gbk",0,0,1],
c3:function(){return},
bL:function(a){var z,y
z=this.r
if(z==null){z=new P.jG(null,null,0,[H.G(this,"av",0)])
this.r=z}z.D(0,a)
y=this.e
if((y&64)===0){y=(y|64)>>>0
this.e=y
if(y<128)this.r.bC(this)}},
bo:function(a){var z=this.e
this.e=(z|32)>>>0
this.d.cA(this.a,a)
this.e=(this.e&4294967263)>>>0
this.bP((z&4)!==0)},
bp:function(a,b){var z,y
z=this.e
y=new P.iN(this,a,b)
if((z&1)!==0){this.e=(z|16)>>>0
this.bN()
z=this.f
if(!!J.k(z).$isar&&z!==$.$get$be())z.ei(y)
else y.$0()}else{y.$0()
this.bP((z&4)!==0)}},
aL:function(){var z,y
z=new P.iM(this)
this.bN()
this.e=(this.e|16)>>>0
y=this.f
if(!!J.k(y).$isar&&y!==$.$get$be())y.ei(z)
else z.$0()},
dd:function(a){var z=this.e
this.e=(z|32)>>>0
a.$0()
this.e=(this.e&4294967263)>>>0
this.bP((z&4)!==0)},
bP:function(a){var z,y
if((this.e&64)!==0){z=this.r
z=z.gJ(z)}else z=!1
if(z){z=(this.e&4294967231)>>>0
this.e=z
if((z&4)!==0)if(z<128){z=this.r
z=z==null||z.gJ(z)}else z=!1
else z=!1
if(z)this.e=(this.e&4294967291)>>>0}for(;!0;a=y){z=this.e
if((z&8)!==0){this.r=null
return}y=(z&4)!==0
if(a===y)break
this.e=(z^32)>>>0
if(y)this.bj()
else this.bl()
this.e=(this.e&4294967263)>>>0}z=this.e
if((z&64)!==0&&z<128)this.r.bC(this)},
cQ:function(a,b,c,d,e){var z,y
z=a==null?P.kb():a
y=this.d
y.toString
this.a=z
this.b=P.eA(b==null?P.kc():b,y)
this.c=c==null?P.eL():c}},
iN:{"^":"h:1;a,b,c",
$0:function(){var z,y,x,w,v,u
z=this.a
y=z.e
if((y&8)!==0&&(y&16)===0)return
z.e=(y|32)>>>0
y=z.b
x=H.ay(y,{func:1,args:[P.e,P.bl]})
w=z.d
v=this.b
u=z.b
if(x)w.i3(u,v,this.c)
else w.cA(u,v)
z.e=(z.e&4294967263)>>>0}},
iM:{"^":"h:1;a",
$0:function(){var z,y
z=this.a
y=z.e
if((y&16)===0)return
z.e=(y|42)>>>0
z.d.cw(z.c)
z.e=(z.e&4294967263)>>>0}},
jF:{"^":"a3;$ti",
U:function(a,b,c,d){return this.a.fV(a,d,c,!0===b)},
aW:function(a,b,c){return this.U(a,null,b,c)}},
ee:{"^":"e;R:a@"},
iS:{"^":"ee;b,a,$ti",
cs:function(a){a.bo(this.b)}},
iU:{"^":"ee;aj:b>,ab:c<,a",
cs:function(a){a.bp(this.b,this.c)}},
iT:{"^":"e;",
cs:function(a){a.aL()},
gR:function(){return},
sR:function(a){throw H.c(new P.X("No events after a done."))}},
ju:{"^":"e;a5:a<",
bC:function(a){var z=this.a
if(z===1)return
if(z>=1){this.a=1
return}P.eY(new P.jv(this,a))
this.a=1},
dG:function(){if(this.a===1)this.a=3}},
jv:{"^":"h:2;a,b",
$0:function(){var z,y,x,w
z=this.a
y=z.a
z.a=0
if(y===3)return
x=z.b
w=x.gR()
z.b=w
if(w==null)z.c=null
x.cs(this.b)}},
jG:{"^":"ju;b,c,a,$ti",
gJ:function(a){return this.c==null},
D:function(a,b){var z=this.c
if(z==null){this.c=b
this.b=b}else{z.sR(b)
this.c=b}}},
iV:{"^":"e;af:a<,a5:b<,c,$ti",
gaU:function(){return this.b>=4},
ds:function(){if((this.b&2)!==0)return
var z=this.a
z.toString
P.aL(null,null,z,this.gfM())
this.b=(this.b|2)>>>0},
aY:function(a,b){this.b+=4},
cr:function(a){return this.aY(a,null)},
cu:function(){var z=this.b
if(z>=4){z-=4
this.b=z
if(z<4&&(z&1)===0)this.ds()}},
au:function(){return $.$get$be()},
aL:[function(){var z=(this.b&4294967293)>>>0
this.b=z
if(z>=4)return
this.b=(z|1)>>>0
z=this.c
if(z!=null)this.a.cw(z)},"$0","gfM",0,0,1]},
bo:{"^":"a3;$ti",
U:function(a,b,c,d){return this.f9(a,d,c,!0===b)},
aW:function(a,b,c){return this.U(a,null,b,c)},
f9:function(a,b,c,d){return P.j1(this,a,b,c,d,H.G(this,"bo",0),H.G(this,"bo",1))},
de:function(a,b){b.aD(a)},
df:function(a,b,c){c.ap(a,b)},
$asa3:function(a,b){return[b]}},
eh:{"^":"av;x,y,a,b,c,d,e,f,r,$ti",
aD:function(a){if((this.e&2)!==0)return
this.eM(a)},
ap:function(a,b){if((this.e&2)!==0)return
this.eN(a,b)},
bj:[function(){var z=this.y
if(z==null)return
z.cr(0)},"$0","gbi",0,0,1],
bl:[function(){var z=this.y
if(z==null)return
z.cu()},"$0","gbk",0,0,1],
c3:function(){var z=this.y
if(z!=null){this.y=null
return z.au()}return},
ic:[function(a){this.x.de(a,this)},"$1","gfj",2,0,function(){return H.b4(function(a,b){return{func:1,v:true,args:[a]}},this.$receiver,"eh")},9],
ig:[function(a,b){this.x.df(a,b,this)},"$2","gfl",4,0,13,4,5],
ie:[function(){this.cU()},"$0","gfk",0,0,1],
eY:function(a,b,c,d,e,f,g){this.y=this.x.a.aW(this.gfj(),this.gfk(),this.gfl())},
$asav:function(a,b){return[b]},
v:{
j1:function(a,b,c,d,e,f,g){var z,y
z=$.q
y=e?1:0
y=new P.eh(a,null,null,null,null,z,y,null,null,[f,g])
y.cQ(b,c,d,e,g)
y.eY(a,b,c,d,e,f,g)
return y}}},
js:{"^":"bo;b,a,$ti",
de:function(a,b){var z,y,x,w
z=null
try{z=this.b.$1(a)}catch(w){y=H.C(w)
x=H.S(w)
P.eu(b,y,x)
return}b.aD(z)}},
jd:{"^":"bo;b,c,a,$ti",
df:function(a,b,c){var z,y,x,w,v
z=!0
if(z===!0)try{P.jY(this.b,a,b)}catch(w){y=H.C(w)
x=H.S(w)
v=y
if(v==null?a==null:v===a)c.ap(a,b)
else P.eu(c,y,x)
return}else c.ap(a,b)},
$asbo:function(a){return[a,a]},
$asa3:null},
bu:{"^":"e;aj:a>,ab:b<",
k:function(a){return H.b(this.a)},
$isJ:1},
jS:{"^":"e;"},
k2:{"^":"h:2;a,b",
$0:function(){var z,y,x
z=this.a
y=z.a
if(y==null){x=new P.dB()
z.a=x
z=x}else z=y
y=this.b
if(y==null)throw H.c(z)
x=H.c(z)
x.stack=J.A(y)
throw x}},
jx:{"^":"jS;",
cw:function(a){var z,y,x,w
try{if(C.b===$.q){x=a.$0()
return x}x=P.eB(null,null,this,a)
return x}catch(w){z=H.C(w)
y=H.S(w)
x=P.aK(null,null,this,z,y)
return x}},
cA:function(a,b){var z,y,x,w
try{if(C.b===$.q){x=a.$1(b)
return x}x=P.eD(null,null,this,a,b)
return x}catch(w){z=H.C(w)
y=H.S(w)
x=P.aK(null,null,this,z,y)
return x}},
i3:function(a,b,c){var z,y,x,w
try{if(C.b===$.q){x=a.$2(b,c)
return x}x=P.eC(null,null,this,a,b,c)
return x}catch(w){z=H.C(w)
y=H.S(w)
x=P.aK(null,null,this,z,y)
return x}},
cc:function(a,b){if(b)return new P.jy(this,a)
else return new P.jz(this,a)},
h6:function(a,b){return new P.jA(this,a)},
h:function(a,b){return},
e9:function(a){if($.q===C.b)return a.$0()
return P.eB(null,null,this,a)},
cz:function(a,b){if($.q===C.b)return a.$1(b)
return P.eD(null,null,this,a,b)},
i2:function(a,b,c){if($.q===C.b)return a.$2(b,c)
return P.eC(null,null,this,a,b,c)}},
jy:{"^":"h:2;a,b",
$0:function(){return this.a.cw(this.b)}},
jz:{"^":"h:2;a,b",
$0:function(){return this.a.e9(this.b)}},
jA:{"^":"h:0;a,b",
$1:[function(a){return this.a.cA(this.b,a)},null,null,2,0,null,24,"call"]}}],["","",,P,{"^":"",
hA:function(a,b){return new H.U(0,null,null,null,null,null,0,[a,b])},
bC:function(){return new H.U(0,null,null,null,null,null,0,[null,null])},
at:function(a){return H.kk(a,new H.U(0,null,null,null,null,null,0,[null,null]))},
he:function(a,b,c){var z,y
if(P.cG(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}z=[]
y=$.$get$b3()
y.push(a)
try{P.jZ(a,z)}finally{if(0>=y.length)return H.a(y,-1)
y.pop()}y=P.dR(b,z,", ")+c
return y.charCodeAt(0)==0?y:y},
bB:function(a,b,c){var z,y,x
if(P.cG(a))return b+"..."+c
z=new P.aG(b)
y=$.$get$b3()
y.push(a)
try{x=z
x.sl(P.dR(x.gl(),a,", "))}finally{if(0>=y.length)return H.a(y,-1)
y.pop()}y=z
y.sl(y.gl()+c)
y=z.gl()
return y.charCodeAt(0)==0?y:y},
cG:function(a){var z,y
for(z=0;y=$.$get$b3(),z<y.length;++z)if(a===y[z])return!0
return!1},
jZ:function(a,b){var z,y,x,w,v,u,t,s,r,q
z=a.gK(a)
y=0
x=0
while(!0){if(!(y<80||x<3))break
if(!z.u())return
w=H.b(z.gw())
b.push(w)
y+=w.length+2;++x}if(!z.u()){if(x<=5)return
if(0>=b.length)return H.a(b,-1)
v=b.pop()
if(0>=b.length)return H.a(b,-1)
u=b.pop()}else{t=z.gw();++x
if(!z.u()){if(x<=4){b.push(H.b(t))
return}v=H.b(t)
if(0>=b.length)return H.a(b,-1)
u=b.pop()
y+=v.length+2}else{s=z.gw();++x
for(;z.u();t=s,s=r){r=z.gw();++x
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
a8:function(a,b,c,d){return new P.jl(0,null,null,null,null,null,0,[d])},
dr:function(a,b){var z,y,x
z=P.a8(null,null,null,b)
for(y=a.length,x=0;x<a.length;a.length===y||(0,H.z)(a),++x)z.D(0,a[x])
return z},
cm:function(a){var z,y,x
z={}
if(P.cG(a))return"{...}"
y=new P.aG("")
try{$.$get$b3().push(a)
x=y
x.sl(x.gl()+"{")
z.a=!0
a.a0(0,new P.hE(z,y))
z=y
z.sl(z.gl()+"}")}finally{z=$.$get$b3()
if(0>=z.length)return H.a(z,-1)
z.pop()}z=y.gl()
return z.charCodeAt(0)==0?z:z},
eq:{"^":"U;a,b,c,d,e,f,r,$ti",
aS:function(a){return H.kI(a)&0x3ffffff},
aT:function(a,b){var z,y,x
if(a==null)return-1
z=a.length
for(y=0;y<z;++y){x=a[y].gdQ()
if(x==null?b==null:x===b)return y}return-1},
v:{
b0:function(a,b){return new P.eq(0,null,null,null,null,null,0,[a,b])}}},
jl:{"^":"je;a,b,c,d,e,f,r,$ti",
gK:function(a){var z=new P.ep(this,this.r,null,null)
z.c=this.e
return z},
gj:function(a){return this.a},
N:function(a,b){var z,y
if(typeof b==="string"&&b!=="__proto__"){z=this.b
if(z==null)return!1
return z[b]!=null}else if(typeof b==="number"&&(b&0x3ffffff)===b){y=this.c
if(y==null)return!1
return y[b]!=null}else return this.f8(b)},
f8:function(a){var z=this.d
if(z==null)return!1
return this.bg(z[this.bd(a)],a)>=0},
dW:function(a){var z
if(!(typeof a==="string"&&a!=="__proto__"))z=typeof a==="number"&&(a&0x3ffffff)===a
else z=!0
if(z)return this.N(0,a)?a:null
else return this.ft(a)},
ft:function(a){var z,y,x
z=this.d
if(z==null)return
y=z[this.bd(a)]
x=this.bg(y,a)
if(x<0)return
return J.af(y,x).gbW()},
D:function(a,b){var z,y,x
if(typeof b==="string"&&b!=="__proto__"){z=this.b
if(z==null){y=Object.create(null)
y["<non-identifier-key>"]=y
delete y["<non-identifier-key>"]
this.b=y
z=y}return this.cY(z,b)}else if(typeof b==="number"&&(b&0x3ffffff)===b){x=this.c
if(x==null){y=Object.create(null)
y["<non-identifier-key>"]=y
delete y["<non-identifier-key>"]
this.c=y
x=y}return this.cY(x,b)}else return this.a3(b)},
a3:function(a){var z,y,x
z=this.d
if(z==null){z=P.jn()
this.d=z}y=this.bd(a)
x=z[y]
if(x==null)z[y]=[this.bQ(a)]
else{if(this.bg(x,a)>=0)return!1
x.push(this.bQ(a))}return!0},
H:function(a,b){if(typeof b==="string"&&b!=="__proto__")return this.d0(this.b,b)
else if(typeof b==="number"&&(b&0x3ffffff)===b)return this.d0(this.c,b)
else return this.fE(b)},
fE:function(a){var z,y,x
z=this.d
if(z==null)return!1
y=z[this.bd(a)]
x=this.bg(y,a)
if(x<0)return!1
this.d1(y.splice(x,1)[0])
return!0},
ah:function(a){if(this.a>0){this.f=null
this.e=null
this.d=null
this.c=null
this.b=null
this.a=0
this.r=this.r+1&67108863}},
cY:function(a,b){if(a[b]!=null)return!1
a[b]=this.bQ(b)
return!0},
d0:function(a,b){var z
if(a==null)return!1
z=a[b]
if(z==null)return!1
this.d1(z)
delete a[b]
return!0},
bQ:function(a){var z,y
z=new P.jm(a,null,null)
if(this.e==null){this.f=z
this.e=z}else{y=this.f
z.c=y
y.b=z
this.f=z}++this.a
this.r=this.r+1&67108863
return z},
d1:function(a){var z,y
z=a.gd_()
y=a.gcZ()
if(z==null)this.e=y
else z.b=y
if(y==null)this.f=z
else y.sd_(z);--this.a
this.r=this.r+1&67108863},
bd:function(a){return J.T(a)&0x3ffffff},
bg:function(a,b){var z,y
if(a==null)return-1
z=a.length
for(y=0;y<z;++y)if(J.N(a[y].gbW(),b))return y
return-1},
$isj:1,
$asj:null,
v:{
jn:function(){var z=Object.create(null)
z["<non-identifier-key>"]=z
delete z["<non-identifier-key>"]
return z}}},
jm:{"^":"e;bW:a<,cZ:b<,d_:c@"},
ep:{"^":"e;a,b,c,d",
gw:function(){return this.d},
u:function(){var z=this.a
if(this.b!==z.r)throw H.c(new P.ah(z))
else{z=this.c
if(z==null){this.d=null
return!1}else{this.d=z.gbW()
this.c=this.c.gcZ()
return!0}}}},
je:{"^":"ib;$ti"},
ci:{"^":"hM;$ti"},
hM:{"^":"e+a0;",$asf:null,$asj:null,$isf:1,$isj:1},
a0:{"^":"e;$ti",
gK:function(a){return new H.cj(a,this.gj(a),0,null)},
O:function(a,b){return this.h(a,b)},
am:function(a,b){return new H.bk(a,b,[H.G(a,"a0",0),null])},
D:function(a,b){var z=this.gj(a)
this.sj(a,z+1)
this.n(a,z,b)},
a2:["cN",function(a,b,c,d,e){var z,y,x,w,v
P.cr(b,c,this.gj(a),null,null,null)
z=c-b
if(z===0)return
if(H.br(d,"$isf",[H.G(a,"a0",0)],"$asf")){y=e
x=d}else{x=new H.cs(d,e,null,[H.G(d,"a0",0)]).b0(0,!1)
y=0}w=J.B(x)
if(y+z>w.gj(x))throw H.c(H.dm())
if(y<b)for(v=z-1;v>=0;--v)this.n(a,b+v,w.h(x,y+v))
else for(v=0;v<z;++v)this.n(a,b+v,w.h(x,y+v))}],
ay:function(a,b){var z=this.h(a,b)
this.a2(a,b,this.gj(a)-1,a,b+1)
this.sj(a,this.gj(a)-1)
return z},
k:function(a){return P.bB(a,"[","]")},
$isf:1,
$asf:null,
$isj:1,
$asj:null},
jQ:{"^":"e;",
n:function(a,b,c){throw H.c(new P.t("Cannot modify unmodifiable map"))},
$isV:1},
hC:{"^":"e;",
h:function(a,b){return this.a.h(0,b)},
n:function(a,b,c){this.a.n(0,b,c)},
a0:function(a,b){this.a.a0(0,b)},
gJ:function(a){var z=this.a
return z.gJ(z)},
gj:function(a){var z=this.a
return z.gj(z)},
k:function(a){return this.a.k(0)},
$isV:1},
e9:{"^":"hC+jQ;$ti",$asV:null,$isV:1},
hE:{"^":"h:5;a,b",
$2:function(a,b){var z,y
z=this.a
if(!z.a)this.b.l+=", "
z.a=!1
z=this.b
y=z.l+=H.b(a)
z.l=y+": "
z.l+=H.b(b)}},
hB:{"^":"aW;a,b,c,d,$ti",
gK:function(a){return new P.jo(this,this.c,this.d,this.b,null)},
gJ:function(a){return this.b===this.c},
gj:function(a){return(this.c-this.b&this.a.length-1)>>>0},
O:function(a,b){var z,y,x,w
z=(this.c-this.b&this.a.length-1)>>>0
if(0>b||b>=z)H.y(P.as(b,this,"index",null,z))
y=this.a
x=y.length
w=(this.b+b&x-1)>>>0
if(w<0||w>=x)return H.a(y,w)
return y[w]},
D:function(a,b){this.a3(b)},
ah:function(a){var z,y,x,w,v
z=this.b
y=this.c
if(z!==y){for(x=this.a,w=x.length,v=w-1;z!==y;z=(z+1&v)>>>0){if(z<0||z>=w)return H.a(x,z)
x[z]=null}this.c=0
this.b=0;++this.d}},
k:function(a){return P.bB(this,"{","}")},
e8:function(){var z,y,x,w
z=this.b
if(z===this.c)throw H.c(H.cc());++this.d
y=this.a
x=y.length
if(z>=x)return H.a(y,z)
w=y[z]
y[z]=null
this.b=(z+1&x-1)>>>0
return w},
a3:function(a){var z,y,x
z=this.a
y=this.c
x=z.length
if(y<0||y>=x)return H.a(z,y)
z[y]=a
x=(y+1&x-1)>>>0
this.c=x
if(this.b===x)this.dc();++this.d},
dc:function(){var z,y,x,w
z=new Array(this.a.length*2)
z.fixed$length=Array
y=H.o(z,this.$ti)
z=this.a
x=this.b
w=z.length-x
C.a.a2(y,0,w,z,x)
C.a.a2(y,w,w+this.b,this.a,0)
this.b=0
this.c=this.a.length
this.a=y},
eT:function(a,b){var z=new Array(8)
z.fixed$length=Array
this.a=H.o(z,[b])},
$asj:null,
v:{
ck:function(a,b){var z=new P.hB(null,0,0,0,[b])
z.eT(a,b)
return z}}},
jo:{"^":"e;a,b,c,d,e",
gw:function(){return this.e},
u:function(){var z,y,x
z=this.a
if(this.c!==z.d)H.y(new P.ah(z))
y=this.d
if(y===this.b){this.e=null
return!1}z=z.a
x=z.length
if(y>=x)return H.a(z,y)
this.e=z[y]
this.d=(y+1&x-1)>>>0
return!0}},
ic:{"^":"e;$ti",
P:function(a,b){var z
for(z=J.L(b);z.u();)this.D(0,z.gw())},
am:function(a,b){return new H.de(this,b,[H.H(this,0),null])},
k:function(a){return P.bB(this,"{","}")},
$isj:1,
$asj:null},
ib:{"^":"ic;$ti"}}],["","",,P,{"^":"",
bQ:function(a){var z
if(a==null)return
if(typeof a!="object")return a
if(Object.getPrototypeOf(a)!==Array.prototype)return new P.jg(a,Object.create(null),null)
for(z=0;z<a.length;++z)a[z]=P.bQ(a[z])
return a},
k1:function(a,b){var z,y,x,w
if(typeof a!=="string")throw H.c(H.I(a))
z=null
try{z=JSON.parse(a)}catch(x){y=H.C(x)
w=String(y)
throw H.c(new P.c9(w,null,null))}w=P.bQ(z)
return w},
mE:[function(a){return a.ik()},"$1","kf",2,0,0,7],
jg:{"^":"e;a,b,c",
h:function(a,b){var z,y
z=this.b
if(z==null)return this.c.h(0,b)
else if(typeof b!=="string")return
else{y=z[b]
return typeof y=="undefined"?this.fA(b):y}},
gj:function(a){var z
if(this.b==null){z=this.c
z=z.gj(z)}else z=this.be().length
return z},
gJ:function(a){var z
if(this.b==null){z=this.c
z=z.gj(z)}else z=this.be().length
return z===0},
n:function(a,b,c){var z,y
if(this.b==null)this.c.n(0,b,c)
else if(this.a_(b)){z=this.b
z[b]=c
y=this.a
if(y==null?z!=null:y!==z)y[b]=null}else this.fY().n(0,b,c)},
a_:function(a){if(this.b==null)return this.c.a_(a)
if(typeof a!=="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
a0:function(a,b){var z,y,x,w
if(this.b==null)return this.c.a0(0,b)
z=this.be()
for(y=0;y<z.length;++y){x=z[y]
w=this.b[x]
if(typeof w=="undefined"){w=P.bQ(this.a[x])
this.b[x]=w}b.$2(x,w)
if(z!==this.c)throw H.c(new P.ah(this))}},
k:function(a){return P.cm(this)},
be:function(){var z=this.c
if(z==null){z=Object.keys(this.a)
this.c=z}return z},
fY:function(){var z,y,x,w,v
if(this.b==null)return this.c
z=P.hA(P.p,null)
y=this.be()
for(x=0;w=y.length,x<w;++x){v=y[x]
z.n(0,v,this.h(0,v))}if(w===0)y.push(null)
else C.a.sj(y,0)
this.b=null
this.a=null
this.c=z
return z},
fA:function(a){var z
if(!Object.prototype.hasOwnProperty.call(this.a,a))return
z=P.bQ(this.a[a])
return this.b[a]=z},
$isV:1,
$asV:function(){return[P.p,null]}},
fz:{"^":"e;"},
d8:{"^":"e;"},
cg:{"^":"J;a,b",
k:function(a){if(this.b!=null)return"Converting object to an encodable object failed."
else return"Converting object did not return an encodable object."}},
hu:{"^":"cg;a,b",
k:function(a){return"Cyclic error in JSON stringify"}},
ht:{"^":"fz;a,b",
he:function(a,b){var z=P.k1(a,this.ghf().a)
return z},
hd:function(a){return this.he(a,null)},
hq:function(a,b){var z=this.ghr()
z=P.ji(a,z.b,z.a)
return z},
hp:function(a){return this.hq(a,null)},
ghr:function(){return C.F},
ghf:function(){return C.E}},
hw:{"^":"d8;dR:a<,b"},
hv:{"^":"d8;a"},
jj:{"^":"e;",
ek:function(a){var z,y,x,w,v,u,t
z=J.B(a)
y=z.gj(a)
if(typeof y!=="number")return H.d(y)
x=this.c
w=0
v=0
for(;v<y;++v){u=z.cf(a,v)
if(u>92)continue
if(u<32){if(v>w)x.l+=z.ac(a,w,v)
w=v+1
x.l+=H.W(92)
switch(u){case 8:x.l+=H.W(98)
break
case 9:x.l+=H.W(116)
break
case 10:x.l+=H.W(110)
break
case 12:x.l+=H.W(102)
break
case 13:x.l+=H.W(114)
break
default:x.l+=H.W(117)
x.l+=H.W(48)
x.l+=H.W(48)
t=u>>>4&15
x.l+=H.W(t<10?48+t:87+t)
t=u&15
x.l+=H.W(t<10?48+t:87+t)
break}}else if(u===34||u===92){if(v>w)x.l+=z.ac(a,w,v)
w=v+1
x.l+=H.W(92)
x.l+=H.W(u)}}if(w===0)x.l+=H.b(a)
else if(w<y)x.l+=z.ac(a,w,y)},
bO:function(a){var z,y,x,w
for(z=this.a,y=z.length,x=0;x<y;++x){w=z[x]
if(a==null?w==null:a===w)throw H.c(new P.hu(a,null))}z.push(a)},
bA:function(a){var z,y,x,w
if(this.ej(a))return
this.bO(a)
try{z=this.b.$1(a)
if(!this.ej(z))throw H.c(new P.cg(a,null))
x=this.a
if(0>=x.length)return H.a(x,-1)
x.pop()}catch(w){y=H.C(w)
throw H.c(new P.cg(a,y))}},
ej:function(a){var z,y
if(typeof a==="number"){if(!isFinite(a))return!1
this.c.l+=C.e.k(a)
return!0}else if(a===!0){this.c.l+="true"
return!0}else if(a===!1){this.c.l+="false"
return!0}else if(a==null){this.c.l+="null"
return!0}else if(typeof a==="string"){z=this.c
z.l+='"'
this.ek(a)
z.l+='"'
return!0}else{z=J.k(a)
if(!!z.$isf){this.bO(a)
this.i7(a)
z=this.a
if(0>=z.length)return H.a(z,-1)
z.pop()
return!0}else if(!!z.$isV){this.bO(a)
y=this.i8(a)
z=this.a
if(0>=z.length)return H.a(z,-1)
z.pop()
return y}else return!1}},
i7:function(a){var z,y,x
z=this.c
z.l+="["
y=J.B(a)
if(y.gj(a)>0){this.bA(y.h(a,0))
for(x=1;x<y.gj(a);++x){z.l+=","
this.bA(y.h(a,x))}}z.l+="]"},
i8:function(a){var z,y,x,w,v,u,t
z={}
if(a.gJ(a)){this.c.l+="{}"
return!0}y=a.gj(a)*2
x=new Array(y)
z.a=0
z.b=!0
a.a0(0,new P.jk(z,x))
if(!z.b)return!1
w=this.c
w.l+="{"
for(v='"',u=0;u<y;u+=2,v=',"'){w.l+=v
this.ek(x[u])
w.l+='":'
t=u+1
if(t>=y)return H.a(x,t)
this.bA(x[t])}w.l+="}"
return!0}},
jk:{"^":"h:5;a,b",
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
jh:{"^":"jj;c,a,b",v:{
ji:function(a,b,c){var z,y,x
z=new P.aG("")
y=new P.jh(z,[],P.kf())
y.bA(a)
x=z.l
return x.charCodeAt(0)==0?x:x}}}}],["","",,P,{"^":"",
bd:function(a){if(typeof a==="number"||typeof a==="boolean"||null==a)return J.A(a)
if(typeof a==="string")return JSON.stringify(a)
return P.fR(a)},
fR:function(a){var z=J.k(a)
if(!!z.$ish)return z.k(a)
return H.bH(a)},
bz:function(a){return new P.j0(a)},
aF:function(a,b,c){var z,y
z=H.o([],[c])
for(y=J.L(a);y.u();)z.push(y.gw())
return z},
kH:function(a,b){var z,y
z=C.d.ef(a)
y=H.dI(z,null,P.kh())
if(y!=null)return y
y=H.i4(z,P.kg())
if(y!=null)return y
throw H.c(new P.c9(a,null,null))},
mM:[function(a){return},"$1","kh",2,0,17],
mL:[function(a){return},"$1","kg",2,0,18],
bW:function(a){H.kJ(H.b(a))},
hJ:{"^":"h:14;a,b",
$2:function(a,b){var z,y,x
z=this.b
y=this.a
z.l+=y.a
x=z.l+=H.b(a.gfu())
z.l=x+": "
z.l+=H.b(P.bd(b))
y.a=", "}},
cH:{"^":"e;"},
"+bool":0,
aT:{"^":"e;a,b",
B:function(a,b){if(b==null)return!1
if(!(b instanceof P.aT))return!1
return this.a===b.a&&this.b===b.b},
gE:function(a){var z=this.a
return(z^C.e.c9(z,30))&1073741823},
k:function(a){var z,y,x,w,v,u,t
z=P.fI(H.i3(this))
y=P.bc(H.i1(this))
x=P.bc(H.hY(this))
w=P.bc(H.hZ(this))
v=P.bc(H.i0(this))
u=P.bc(H.i2(this))
t=P.fJ(H.i_(this))
if(this.b)return z+"-"+y+"-"+x+" "+w+":"+v+":"+u+"."+t+"Z"
else return z+"-"+y+"-"+x+" "+w+":"+v+":"+u+"."+t},
D:function(a,b){return P.fH(C.e.i(this.a,b.gij()),this.b)},
ghT:function(){return this.a},
cP:function(a,b){var z
if(!(Math.abs(this.a)>864e13))z=!1
else z=!0
if(z)throw H.c(P.aR(this.ghT()))},
v:{
fH:function(a,b){var z=new P.aT(a,b)
z.cP(a,b)
return z},
fI:function(a){var z,y
z=Math.abs(a)
y=a<0?"-":""
if(z>=1000)return""+a
if(z>=100)return y+"0"+H.b(z)
if(z>=10)return y+"00"+H.b(z)
return y+"000"+H.b(z)},
fJ:function(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
bc:function(a){if(a>=10)return""+a
return"0"+a}}},
ad:{"^":"b6;"},
"+double":0,
aD:{"^":"e;bf:a<",
i:function(a,b){return new P.aD(this.a+b.gbf())},
G:function(a,b){return new P.aD(this.a-b.gbf())},
C:function(a,b){if(typeof b!=="number")return H.d(b)
return new P.aD(C.e.aZ(this.a*b))},
bJ:function(a,b){if(b===0)throw H.c(new P.fX())
return new P.aD(C.c.bJ(this.a,b))},
X:function(a,b){return C.c.X(this.a,b.gbf())},
an:function(a,b){return C.c.an(this.a,b.gbf())},
B:function(a,b){if(b==null)return!1
if(!(b instanceof P.aD))return!1
return this.a===b.a},
gE:function(a){return this.a&0x1FFFFFFF},
k:function(a){var z,y,x,w,v
z=new P.fP()
y=this.a
if(y<0)return"-"+new P.aD(0-y).k(0)
x=z.$1(C.c.bq(y,6e7)%60)
w=z.$1(C.c.bq(y,1e6)%60)
v=new P.fO().$1(y%1e6)
return""+C.c.bq(y,36e8)+":"+H.b(x)+":"+H.b(w)+"."+H.b(v)}},
fO:{"^":"h:6;",
$1:function(a){if(a>=1e5)return""+a
if(a>=1e4)return"0"+a
if(a>=1000)return"00"+a
if(a>=100)return"000"+a
if(a>=10)return"0000"+a
return"00000"+a}},
fP:{"^":"h:6;",
$1:function(a){if(a>=10)return""+a
return"0"+a}},
J:{"^":"e;",
gab:function(){return H.S(this.$thrownJsError)}},
dB:{"^":"J;",
k:function(a){return"Throw of null."}},
ao:{"^":"J;a,b,c,d",
gbY:function(){return"Invalid argument"+(!this.a?"(s)":"")},
gbX:function(){return""},
k:function(a){var z,y,x,w,v,u
z=this.c
y=z!=null?" ("+z+")":""
z=this.d
x=z==null?"":": "+H.b(z)
w=this.gbY()+y+x
if(!this.a)return w
v=this.gbX()
u=P.bd(this.b)
return w+v+": "+H.b(u)},
v:{
aR:function(a){return new P.ao(!1,null,null,a)},
d_:function(a,b,c){return new P.ao(!0,a,b,c)}}},
dK:{"^":"ao;e,f,a,b,c,d",
gbY:function(){return"RangeError"},
gbX:function(){var z,y,x
z=this.e
if(z==null){z=this.f
y=z!=null?": Not less than or equal to "+H.b(z):""}else{x=this.f
if(x==null)y=": Not greater than or equal to "+H.b(z)
else if(x>z)y=": Not in range "+H.b(z)+".."+H.b(x)+", inclusive"
else y=x<z?": Valid value range is empty":": Only valid value is "+H.b(z)}return y},
v:{
aZ:function(a,b,c){return new P.dK(null,null,!0,a,b,"Value not in range")},
E:function(a,b,c,d,e){return new P.dK(b,c,!0,a,d,"Invalid value")},
cr:function(a,b,c,d,e,f){if(0>a||a>c)throw H.c(P.E(a,0,c,"start",f))
if(a>b||b>c)throw H.c(P.E(b,a,c,"end",f))
return b}}},
fV:{"^":"ao;e,j:f>,a,b,c,d",
gbY:function(){return"RangeError"},
gbX:function(){if(J.bY(this.b,0))return": index must not be negative"
var z=this.f
if(z===0)return": no indices are valid"
return": index should be less than "+H.b(z)},
v:{
as:function(a,b,c,d,e){var z=e!=null?e:J.ag(b)
return new P.fV(b,z,!0,a,c,"Index out of range")}}},
hI:{"^":"J;a,b,c,d,e",
k:function(a){var z,y,x,w,v,u,t,s
z={}
y=new P.aG("")
z.a=""
for(x=this.c,w=x.length,v=0;v<w;++v){u=x[v]
y.l+=z.a
y.l+=H.b(P.bd(u))
z.a=", "}this.d.a0(0,new P.hJ(z,y))
t=P.bd(this.a)
s=y.k(0)
x="NoSuchMethodError: method not found: '"+H.b(this.b.a)+"'\nReceiver: "+H.b(t)+"\nArguments: ["+s+"]"
return x},
v:{
dx:function(a,b,c,d,e){return new P.hI(a,b,c,d,e)}}},
t:{"^":"J;a",
k:function(a){return"Unsupported operation: "+this.a}},
e8:{"^":"J;a",
k:function(a){var z=this.a
return z!=null?"UnimplementedError: "+H.b(z):"UnimplementedError"}},
X:{"^":"J;a",
k:function(a){return"Bad state: "+this.a}},
ah:{"^":"J;a",
k:function(a){var z=this.a
if(z==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+H.b(P.bd(z))+"."}},
hN:{"^":"e;",
k:function(a){return"Out of Memory"},
gab:function(){return},
$isJ:1},
dP:{"^":"e;",
k:function(a){return"Stack Overflow"},
gab:function(){return},
$isJ:1},
fG:{"^":"J;a",
k:function(a){var z=this.a
return z==null?"Reading static variable during its initialization":"Reading static variable '"+H.b(z)+"' during its initialization"}},
j0:{"^":"e;a",
k:function(a){var z=this.a
if(z==null)return"Exception"
return"Exception: "+H.b(z)},
$isby:1},
c9:{"^":"e;a,b,by:c>",
k:function(a){var z,y,x
z=this.a
y=""!==z?"FormatException: "+z:"FormatException"
x=this.b
if(typeof x!=="string")return y
if(x.length>78)x=C.d.ac(x,0,75)+"..."
return y+"\n"+x},
$isby:1},
fX:{"^":"e;",
k:function(a){return"IntegerDivisionByZeroException"},
$isby:1},
fS:{"^":"e;a,di",
k:function(a){return"Expando:"+H.b(this.a)},
h:function(a,b){var z,y
z=this.di
if(typeof z!=="string"){if(b==null||typeof b==="boolean"||typeof b==="number"||typeof b==="string")H.y(P.d_(b,"Expandos are not allowed on strings, numbers, booleans or null",null))
return z.get(b)}y=H.cq(b,"expando$values")
return y==null?null:H.cq(y,z)},
n:function(a,b,c){var z,y
z=this.di
if(typeof z!=="string")z.set(b,c)
else{y=H.cq(b,"expando$values")
if(y==null){y=new P.e()
H.dJ(b,"expando$values",y)}H.dJ(y,z,c)}}},
r:{"^":"b6;"},
"+int":0,
Z:{"^":"e;$ti",
am:function(a,b){return H.bD(this,b,H.G(this,"Z",0),null)},
cH:["eG",function(a,b){return new H.ea(this,b,[H.G(this,"Z",0)])}],
b0:function(a,b){return P.aF(this,!0,H.G(this,"Z",0))},
cE:function(a){return this.b0(a,!0)},
gj:function(a){var z,y
z=this.gK(this)
for(y=0;z.u();)++y
return y},
gao:function(a){var z,y
z=this.gK(this)
if(!z.u())throw H.c(H.cc())
y=z.gw()
if(z.u())throw H.c(H.hf())
return y},
O:function(a,b){var z,y,x
if(b<0)H.y(P.E(b,0,null,"index",null))
for(z=this.gK(this),y=0;z.u();){x=z.gw()
if(b===y)return x;++y}throw H.c(P.as(b,this,"index",null,y))},
k:function(a){return P.he(this,"(",")")}},
dn:{"^":"e;"},
f:{"^":"e;$ti",$asf:null,$isj:1,$asj:null},
"+List":0,
aX:{"^":"e;",
gE:function(a){return P.e.prototype.gE.call(this,this)},
k:function(a){return"null"}},
"+Null":0,
b6:{"^":"e;"},
"+num":0,
e:{"^":";",
B:function(a,b){return this===b},
gE:function(a){return H.al(this)},
k:["eK",function(a){return H.bH(this)}],
cp:function(a,b){throw H.c(P.dx(this,b.gdX(),b.ge4(),b.gdY(),null))},
toString:function(){return this.k(this)}},
bl:{"^":"e;"},
p:{"^":"e;"},
"+String":0,
aG:{"^":"e;l@",
gj:function(a){return this.l.length},
k:function(a){var z=this.l
return z.charCodeAt(0)==0?z:z},
v:{
dR:function(a,b,c){var z=J.L(b)
if(!z.u())return a
if(c.length===0){do a+=H.b(z.gw())
while(z.u())}else{a+=H.b(z.gw())
for(;z.u();)a=a+c+H.b(z.gw())}return a}}},
bm:{"^":"e;"}}],["","",,W,{"^":"",
kQ:function(){return window},
fF:function(a){return a.replace(/^-ms-/,"ms-").replace(/-([\da-z])/ig,function(b,c){return c.toUpperCase()})},
fQ:function(a,b,c){var z,y
z=document.body
y=(z&&C.l).T(z,a,b,c)
y.toString
z=new H.ea(new W.a4(y),new W.ke(),[W.u])
return z.gao(z)},
aU:function(a){var z,y,x,w
z="element tag unavailable"
try{y=J.m(a)
x=y.geb(a)
if(typeof x==="string")z=y.geb(a)}catch(w){H.C(w)}return z},
ax:function(a,b){a=536870911&a+b
a=536870911&a+((524287&a)<<10)
return a^a>>>6},
en:function(a){a=536870911&a+((67108863&a)<<3)
a^=a>>>11
return 536870911&a+((16383&a)<<15)},
ev:function(a){var z
if(a==null)return
if("postMessage" in a){z=W.iR(a)
if(!!J.k(z).$isO)return z
return}else return a},
eH:function(a){var z=$.q
if(z===C.b)return a
return z.h6(a,!0)},
w:{"^":"aq;","%":"HTMLBRElement|HTMLContentElement|HTMLDListElement|HTMLDataListElement|HTMLDetailsElement|HTMLDialogElement|HTMLDirectoryElement|HTMLFontElement|HTMLFrameElement|HTMLHRElement|HTMLHeadElement|HTMLHeadingElement|HTMLHtmlElement|HTMLLabelElement|HTMLLegendElement|HTMLMarqueeElement|HTMLMenuElement|HTMLMenuItemElement|HTMLModElement|HTMLOListElement|HTMLOptGroupElement|HTMLParagraphElement|HTMLPictureElement|HTMLPreElement|HTMLQuoteElement|HTMLScriptElement|HTMLShadowElement|HTMLSourceElement|HTMLSpanElement|HTMLStyleElement|HTMLTableCaptionElement|HTMLTableCellElement|HTMLTableColElement|HTMLTableDataCellElement|HTMLTableHeaderCellElement|HTMLTitleElement|HTMLTrackElement|HTMLUListElement|HTMLUnknownElement;HTMLElement"},
kS:{"^":"w;bw:href}",
k:function(a){return String(a)},
$isi:1,
"%":"HTMLAnchorElement"},
kU:{"^":"w;bw:href}",
k:function(a){return String(a)},
$isi:1,
"%":"HTMLAreaElement"},
kV:{"^":"w;bw:href}","%":"HTMLBaseElement"},
c1:{"^":"i;",$isc1:1,"%":"Blob|File"},
c2:{"^":"w;",$isc2:1,$isO:1,$isi:1,"%":"HTMLBodyElement"},
kW:{"^":"w;L:name=,F:value=","%":"HTMLButtonElement"},
kX:{"^":"w;p:height%,m:width%",
en:function(a,b,c){return a.getContext(b)},
em:function(a,b){return this.en(a,b,null)},
"%":"HTMLCanvasElement"},
kY:{"^":"i;ak:fillStyle},aw:font},eo:globalAlpha},hQ:lineJoin},cm:lineWidth},bH:strokeStyle},cB:textAlign},cC:textBaseline}",
at:function(a){return a.beginPath()},
h8:function(a,b,c,d,e){return a.clearRect(b,c,d,e)},
dK:function(a,b,c,d,e){return a.fillRect(b,c,d,e)},
cn:function(a,b){return a.measureText(b)},
V:function(a){return a.restore()},
S:function(a){return a.save()},
ia:function(a,b){return a.stroke(b)},
bG:function(a){return a.stroke()},
dE:function(a,b,c,d,e,f,g){return a.bezierCurveTo(b,c,d,e,f,g)},
ce:function(a){return a.closePath()},
A:function(a,b,c){return a.lineTo(b,c)},
aX:function(a,b,c){return a.moveTo(b,c)},
M:function(a,b,c,d,e){return a.quadraticCurveTo(b,c,d,e)},
hu:function(a,b,c,d,e){a.fillText(b,c,d)},
ck:function(a,b,c,d){return this.hu(a,b,c,d,null)},
ht:function(a,b){a.fill(b)},
cj:function(a){return this.ht(a,"nonzero")},
"%":"CanvasRenderingContext2D"},
kZ:{"^":"u;j:length=",$isi:1,"%":"CDATASection|CharacterData|Comment|ProcessingInstruction|Text"},
l_:{"^":"fY;j:length=",
cJ:function(a,b){var z=this.fi(a,b)
return z!=null?z:""},
fi:function(a,b){if(W.fF(b) in a)return a.getPropertyValue(b)
else return a.getPropertyValue(P.fK()+b)},
gp:function(a){return a.height},
gm:function(a){return a.width},
"%":"CSS2Properties|CSSStyleDeclaration|MSStyleCSSProperties"},
fY:{"^":"i+fE;"},
fE:{"^":"e;",
gp:function(a){return this.cJ(a,"height")},
gm:function(a){return this.cJ(a,"width")}},
fL:{"^":"w;","%":"HTMLDivElement"},
fM:{"^":"u;",$isi:1,"%":";DocumentFragment"},
l0:{"^":"i;",
k:function(a){return String(a)},
"%":"DOMException"},
fN:{"^":"i;",
k:function(a){return"Rectangle ("+H.b(a.left)+", "+H.b(a.top)+") "+H.b(this.gm(a))+" x "+H.b(this.gp(a))},
B:function(a,b){var z
if(b==null)return!1
z=J.k(b)
if(!z.$isam)return!1
return a.left===z.gaV(b)&&a.top===z.gb1(b)&&this.gm(a)===z.gm(b)&&this.gp(a)===z.gp(b)},
gE:function(a){var z,y,x,w
z=a.left
y=a.top
x=this.gm(a)
w=this.gp(a)
return W.en(W.ax(W.ax(W.ax(W.ax(0,z&0x1FFFFFFF),y&0x1FFFFFFF),x&0x1FFFFFFF),w&0x1FFFFFFF))},
gcF:function(a){return new P.a9(a.left,a.top,[null])},
gcd:function(a){return a.bottom},
gp:function(a){return a.height},
gaV:function(a){return a.left},
gcv:function(a){return a.right},
gb1:function(a){return a.top},
gm:function(a){return a.width},
gq:function(a){return a.x},
gt:function(a){return a.y},
$isam:1,
$asam:I.K,
"%":";DOMRectReadOnly"},
l1:{"^":"i;j:length=",
D:function(a,b){return a.add(b)},
"%":"DOMTokenList"},
ei:{"^":"ci;a,$ti",
gj:function(a){return this.a.length},
h:function(a,b){var z=this.a
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]},
n:function(a,b,c){throw H.c(new P.t("Cannot modify list"))},
sj:function(a,b){throw H.c(new P.t("Cannot modify list"))},
$isf:1,
$asf:null,
$isj:1,
$asj:null},
aq:{"^":"u;dj:namespaceURI=,eb:tagName=",
gh4:function(a){return new W.iW(a)},
gby:function(a){return P.i7(C.e.aZ(a.offsetLeft),C.e.aZ(a.offsetTop),C.e.aZ(a.offsetWidth),C.e.aZ(a.offsetHeight),null)},
k:function(a){return a.localName},
hH:function(a,b,c,d,e){var z,y
z=this.T(a,c,d,e)
switch(b.toLowerCase()){case"beforebegin":a.parentNode.insertBefore(z,a)
break
case"afterbegin":y=a.childNodes
a.insertBefore(z,y.length>0?y[0]:null)
break
case"beforeend":a.appendChild(z)
break
case"afterend":a.parentNode.insertBefore(z,a.nextSibling)
break
default:H.y(P.aR("Invalid position "+b))}},
T:["bI",function(a,b,c,d){var z,y,x,w,v
if(c==null){z=$.dg
if(z==null){z=H.o([],[W.dy])
y=new W.dz(z)
z.push(W.el(null))
z.push(W.es())
$.dg=y
d=y}else d=z
z=$.df
if(z==null){z=new W.et(d)
$.df=z
c=z}else{z.a=d
c=z}}if($.ai==null){z=document
y=z.implementation.createHTMLDocument("")
$.ai=y
$.c7=y.createRange()
y=$.ai
y.toString
x=y.createElement("base")
J.fh(x,z.baseURI)
$.ai.head.appendChild(x)}z=$.ai
if(z.body==null){z.toString
y=z.createElement("body")
z.body=y}z=$.ai
if(!!this.$isc2)w=z.body
else{y=a.tagName
z.toString
w=z.createElement(y)
$.ai.body.appendChild(w)}if("createContextualFragment" in window.Range.prototype&&!C.a.N(C.H,a.tagName)){$.c7.selectNodeContents(w)
v=$.c7.createContextualFragment(b)}else{w.innerHTML=b
v=$.ai.createDocumentFragment()
for(;z=w.firstChild,z!=null;)v.appendChild(z)}z=$.ai.body
if(w==null?z!=null:w!==z)J.fd(w)
c.cK(v)
document.adoptNode(v)
return v},function(a,b,c){return this.T(a,b,c,null)},"hc",null,null,"gii",2,5,null,0,0],
sdS:function(a,b){this.bE(a,b)},
bF:function(a,b,c,d){a.textContent=null
a.appendChild(this.T(a,b,c,d))},
bE:function(a,b){return this.bF(a,b,null,null)},
dL:function(a){return a.focus()},
cI:function(a){return a.getBoundingClientRect()},
gdZ:function(a){return new W.ab(a,"change",!1,[W.a2])},
ge_:function(a){return new W.ab(a,"input",!1,[W.a2])},
ge0:function(a){return new W.ab(a,"mousedown",!1,[W.au])},
ge1:function(a){return new W.ab(a,"mousemove",!1,[W.au])},
ge2:function(a){return new W.ab(a,"mouseup",!1,[W.au])},
$isaq:1,
$isu:1,
$ise:1,
$isi:1,
$isO:1,
"%":";Element"},
ke:{"^":"h:0;",
$1:function(a){return!!J.k(a).$isaq}},
l2:{"^":"w;p:height%,L:name=,m:width%","%":"HTMLEmbedElement"},
l3:{"^":"a2;aj:error=","%":"ErrorEvent"},
a2:{"^":"i;",
hX:function(a){return a.preventDefault()},
$isa2:1,
"%":"AnimationEvent|AnimationPlayerEvent|ApplicationCacheErrorEvent|AudioProcessingEvent|AutocompleteErrorEvent|BeforeInstallPromptEvent|BeforeUnloadEvent|BlobEvent|ClipboardEvent|CloseEvent|CustomEvent|DeviceLightEvent|DeviceMotionEvent|DeviceOrientationEvent|FontFaceSetLoadEvent|GamepadEvent|GeofencingEvent|HashChangeEvent|IDBVersionChangeEvent|MIDIConnectionEvent|MIDIMessageEvent|MediaEncryptedEvent|MediaKeyMessageEvent|MediaQueryListEvent|MediaStreamEvent|MediaStreamTrackEvent|MessageEvent|OfflineAudioCompletionEvent|PageTransitionEvent|PopStateEvent|PresentationConnectionAvailableEvent|PresentationConnectionCloseEvent|ProgressEvent|PromiseRejectionEvent|RTCDTMFToneChangeEvent|RTCDataChannelEvent|RTCIceCandidateEvent|RTCPeerConnectionIceEvent|RelatedEvent|ResourceProgressEvent|SecurityPolicyViolationEvent|ServiceWorkerMessageEvent|SpeechRecognitionEvent|SpeechSynthesisEvent|StorageEvent|TrackEvent|TransitionEvent|USBConnectionEvent|WebGLContextEvent|WebKitTransitionEvent;Event|InputEvent"},
O:{"^":"i;",
dB:function(a,b,c,d){if(c!=null)this.f2(a,b,c,!1)},
e7:function(a,b,c,d){if(c!=null)this.fH(a,b,c,!1)},
f2:function(a,b,c,d){return a.addEventListener(b,H.aO(c,1),!1)},
fH:function(a,b,c,d){return a.removeEventListener(b,H.aO(c,1),!1)},
$isO:1,
"%":"MessagePort;EventTarget"},
fT:{"^":"a2;","%":"ExtendableMessageEvent|FetchEvent|InstallEvent|PushEvent|ServicePortConnectEvent|SyncEvent;ExtendableEvent"},
lm:{"^":"w;L:name=","%":"HTMLFieldSetElement"},
lp:{"^":"w;cb:action=,j:length=,L:name=","%":"HTMLFormElement"},
lq:{"^":"w;p:height%,L:name=,m:width%","%":"HTMLIFrameElement"},
cb:{"^":"i;p:height=,m:width=",$iscb:1,"%":"ImageData"},
lr:{"^":"w;p:height%,m:width%","%":"HTMLImageElement"},
lt:{"^":"w;p:height%,L:name=,F:value=,m:width%",$isaq:1,$isi:1,$isO:1,$isu:1,"%":"HTMLInputElement"},
lz:{"^":"w;L:name=","%":"HTMLKeygenElement"},
lA:{"^":"w;F:value=","%":"HTMLLIElement"},
lC:{"^":"w;bw:href}","%":"HTMLLinkElement"},
lD:{"^":"i;",
k:function(a){return String(a)},
"%":"Location"},
lE:{"^":"w;L:name=","%":"HTMLMapElement"},
hF:{"^":"w;aj:error=","%":"HTMLAudioElement;HTMLMediaElement"},
lH:{"^":"O;",
av:function(a){return a.clone()},
"%":"MediaStream"},
lI:{"^":"w;L:name=","%":"HTMLMetaElement"},
lJ:{"^":"w;F:value=","%":"HTMLMeterElement"},
lK:{"^":"hG;",
i9:function(a,b,c){return a.send(b,c)},
bD:function(a,b){return a.send(b)},
"%":"MIDIOutput"},
hG:{"^":"O;","%":"MIDIInput;MIDIPort"},
au:{"^":"iz;",
gby:function(a){var z,y,x
if(!!a.offsetX)return new P.a9(a.offsetX,a.offsetY,[null])
else{if(!J.k(W.ev(a.target)).$isaq)throw H.c(new P.t("offsetX is only supported on elements"))
z=W.ev(a.target)
y=[null]
x=new P.a9(a.clientX,a.clientY,y).G(0,J.f8(J.f9(z)))
return new P.a9(J.cZ(x.a),J.cZ(x.b),y)}},
"%":"WheelEvent;DragEvent|MouseEvent"},
lV:{"^":"i;",$isi:1,"%":"Navigator"},
a4:{"^":"ci;a",
gao:function(a){var z,y
z=this.a
y=z.childNodes.length
if(y===0)throw H.c(new P.X("No elements"))
if(y>1)throw H.c(new P.X("More than one element"))
return z.firstChild},
D:function(a,b){this.a.appendChild(b)},
P:function(a,b){var z,y,x,w
z=b.a
y=this.a
if(z!==y)for(x=z.childNodes.length,w=0;w<x;++w)y.appendChild(z.firstChild)
return},
ay:function(a,b){var z,y,x
z=this.a
y=z.childNodes
if(b>=y.length)return H.a(y,b)
x=y[b]
z.removeChild(x)
return x},
n:function(a,b,c){var z,y
z=this.a
y=z.childNodes
if(b>>>0!==b||b>=y.length)return H.a(y,b)
z.replaceChild(c,y[b])},
gK:function(a){var z=this.a.childNodes
return new W.dj(z,z.length,-1,null)},
a2:function(a,b,c,d,e){throw H.c(new P.t("Cannot setRange on Node list"))},
gj:function(a){return this.a.childNodes.length},
sj:function(a,b){throw H.c(new P.t("Cannot set length on immutable List."))},
h:function(a,b){var z=this.a.childNodes
if(b>>>0!==b||b>=z.length)return H.a(z,b)
return z[b]},
$asci:function(){return[W.u]},
$asf:function(){return[W.u]},
$asj:function(){return[W.u]}},
u:{"^":"O;cq:parentNode=,hY:previousSibling=",
ghW:function(a){return new W.a4(a)},
ct:function(a){var z=a.parentNode
if(z!=null)z.removeChild(a)},
k:function(a){var z=a.nodeValue
return z==null?this.eF(a):z},
bt:function(a,b){return a.cloneNode(b)},
$isu:1,
$ise:1,
"%":"Document|HTMLDocument|XMLDocument;Node"},
lW:{"^":"h2;",
gj:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.as(b,a,null,null,null))
return a[b]},
n:function(a,b,c){throw H.c(new P.t("Cannot assign element of immutable List."))},
sj:function(a,b){throw H.c(new P.t("Cannot resize immutable List."))},
O:function(a,b){if(b<0||b>=a.length)return H.a(a,b)
return a[b]},
$isf:1,
$asf:function(){return[W.u]},
$isj:1,
$asj:function(){return[W.u]},
$isa_:1,
$asa_:function(){return[W.u]},
$isR:1,
$asR:function(){return[W.u]},
"%":"NodeList|RadioNodeList"},
fZ:{"^":"i+a0;",
$asf:function(){return[W.u]},
$asj:function(){return[W.u]},
$isf:1,
$isj:1},
h2:{"^":"fZ+bA;",
$asf:function(){return[W.u]},
$asj:function(){return[W.u]},
$isf:1,
$isj:1},
lX:{"^":"fT;cb:action=","%":"NotificationEvent"},
lZ:{"^":"w;p:height%,L:name=,m:width%","%":"HTMLObjectElement"},
m_:{"^":"w;F:value=","%":"HTMLOptionElement"},
m0:{"^":"w;L:name=,F:value=","%":"HTMLOutputElement"},
m1:{"^":"w;L:name=,F:value=","%":"HTMLParamElement"},
m3:{"^":"au;p:height=,m:width=","%":"PointerEvent"},
m4:{"^":"w;F:value=","%":"HTMLProgressElement"},
m5:{"^":"i;",
cI:function(a){return a.getBoundingClientRect()},
"%":"Range"},
m8:{"^":"w;j:length=,L:name=,F:value=","%":"HTMLSelectElement"},
m9:{"^":"fM;",
bt:function(a,b){return a.cloneNode(b)},
av:function(a){return a.cloneNode()},
"%":"ShadowRoot"},
ma:{"^":"w;L:name=","%":"HTMLSlotElement"},
mb:{"^":"a2;aj:error=","%":"SpeechRecognitionError"},
ik:{"^":"w;",
T:function(a,b,c,d){var z,y
if("createContextualFragment" in window.Range.prototype)return this.bI(a,b,c,d)
z=W.fQ("<table>"+H.b(b)+"</table>",c,d)
y=document.createDocumentFragment()
y.toString
new W.a4(y).P(0,J.f6(z))
return y},
"%":"HTMLTableElement"},
me:{"^":"w;",
T:function(a,b,c,d){var z,y,x,w
if("createContextualFragment" in window.Range.prototype)return this.bI(a,b,c,d)
z=document
y=z.createDocumentFragment()
z=C.t.T(z.createElement("table"),b,c,d)
z.toString
z=new W.a4(z)
x=z.gao(z)
x.toString
z=new W.a4(x)
w=z.gao(z)
y.toString
w.toString
new W.a4(y).P(0,new W.a4(w))
return y},
"%":"HTMLTableRowElement"},
mf:{"^":"w;",
T:function(a,b,c,d){var z,y,x
if("createContextualFragment" in window.Range.prototype)return this.bI(a,b,c,d)
z=document
y=z.createDocumentFragment()
z=C.t.T(z.createElement("table"),b,c,d)
z.toString
z=new W.a4(z)
x=z.gao(z)
y.toString
x.toString
new W.a4(y).P(0,new W.a4(x))
return y},
"%":"HTMLTableSectionElement"},
dU:{"^":"w;",
bF:function(a,b,c,d){var z
a.textContent=null
z=this.T(a,b,c,d)
a.content.appendChild(z)},
bE:function(a,b){return this.bF(a,b,null,null)},
$isdU:1,
"%":"HTMLTemplateElement"},
mg:{"^":"w;L:name=,F:value=","%":"HTMLTextAreaElement"},
mh:{"^":"i;m:width=","%":"TextMetrics"},
iz:{"^":"a2;","%":"CompositionEvent|FocusEvent|KeyboardEvent|SVGZoomEvent|TextEvent|TouchEvent;UIEvent"},
mm:{"^":"hF;p:height%,m:width%","%":"HTMLVideoElement"},
bL:{"^":"O;",
gh3:function(a){var z,y
z=P.b6
y=new P.ac(0,$.q,null,[z])
this.fg(a)
this.fI(a,W.eH(new W.iC(new P.jN(y,[z]))))
return y},
fI:function(a,b){return a.requestAnimationFrame(H.aO(b,1))},
fg:function(a){if(!!(a.requestAnimationFrame&&a.cancelAnimationFrame))return;(function(b){var z=['ms','moz','webkit','o']
for(var y=0;y<z.length&&!b.requestAnimationFrame;++y){b.requestAnimationFrame=b[z[y]+'RequestAnimationFrame']
b.cancelAnimationFrame=b[z[y]+'CancelAnimationFrame']||b[z[y]+'CancelRequestAnimationFrame']}if(b.requestAnimationFrame&&b.cancelAnimationFrame)return
b.requestAnimationFrame=function(c){return window.setTimeout(function(){c(Date.now())},16)}
b.cancelAnimationFrame=function(c){clearTimeout(c)}})(a)},
$isbL:1,
$isi:1,
$isO:1,
"%":"DOMWindow|Window"},
iC:{"^":"h:0;a",
$1:[function(a){var z=this.a.a
if(z.a!==0)H.y(new P.X("Future already completed"))
z.bc(a)},null,null,2,0,null,25,"call"]},
mr:{"^":"u;L:name=,dj:namespaceURI=","%":"Attr"},
ms:{"^":"i;cd:bottom=,p:height=,aV:left=,cv:right=,b1:top=,m:width=",
k:function(a){return"Rectangle ("+H.b(a.left)+", "+H.b(a.top)+") "+H.b(a.width)+" x "+H.b(a.height)},
B:function(a,b){var z,y,x
if(b==null)return!1
z=J.k(b)
if(!z.$isam)return!1
y=a.left
x=z.gaV(b)
if(y==null?x==null:y===x){y=a.top
x=z.gb1(b)
if(y==null?x==null:y===x){y=a.width
x=z.gm(b)
if(y==null?x==null:y===x){y=a.height
z=z.gp(b)
z=y==null?z==null:y===z}else z=!1}else z=!1}else z=!1
return z},
gE:function(a){var z,y,x,w
z=J.T(a.left)
y=J.T(a.top)
x=J.T(a.width)
w=J.T(a.height)
return W.en(W.ax(W.ax(W.ax(W.ax(0,z),y),x),w))},
gcF:function(a){return new P.a9(a.left,a.top,[null])},
$isam:1,
$asam:I.K,
"%":"ClientRect"},
mt:{"^":"u;",$isi:1,"%":"DocumentType"},
mu:{"^":"fN;",
gp:function(a){return a.height},
gm:function(a){return a.width},
gq:function(a){return a.x},
sq:function(a,b){a.x=b},
gt:function(a){return a.y},
st:function(a,b){a.y=b},
"%":"DOMRect"},
mw:{"^":"w;",$isO:1,$isi:1,"%":"HTMLFrameSetElement"},
mz:{"^":"h3;",
gj:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.as(b,a,null,null,null))
return a[b]},
n:function(a,b,c){throw H.c(new P.t("Cannot assign element of immutable List."))},
sj:function(a,b){throw H.c(new P.t("Cannot resize immutable List."))},
O:function(a,b){if(b<0||b>=a.length)return H.a(a,b)
return a[b]},
$isf:1,
$asf:function(){return[W.u]},
$isj:1,
$asj:function(){return[W.u]},
$isa_:1,
$asa_:function(){return[W.u]},
$isR:1,
$asR:function(){return[W.u]},
"%":"MozNamedAttrMap|NamedNodeMap"},
h_:{"^":"i+a0;",
$asf:function(){return[W.u]},
$asj:function(){return[W.u]},
$isf:1,
$isj:1},
h3:{"^":"h_+bA;",
$asf:function(){return[W.u]},
$asj:function(){return[W.u]},
$isf:1,
$isj:1},
mD:{"^":"O;",$isO:1,$isi:1,"%":"ServiceWorker"},
iJ:{"^":"e;fn:a<",
a0:function(a,b){var z,y,x,w,v
for(z=this.ga9(),y=z.length,x=this.a,w=0;w<z.length;z.length===y||(0,H.z)(z),++w){v=z[w]
b.$2(v,x.getAttribute(v))}},
ga9:function(){var z,y,x,w,v,u
z=this.a.attributes
y=H.o([],[P.p])
for(x=z.length,w=0;w<x;++w){if(w>=z.length)return H.a(z,w)
v=z[w]
u=J.m(v)
if(u.gdj(v)==null)y.push(u.gL(v))}return y},
gJ:function(a){return this.ga9().length===0},
$isV:1,
$asV:function(){return[P.p,P.p]}},
iW:{"^":"iJ;a",
h:function(a,b){return this.a.getAttribute(b)},
n:function(a,b,c){this.a.setAttribute(b,c)},
gj:function(a){return this.ga9().length}},
eg:{"^":"a3;a,b,c,$ti",
U:function(a,b,c,d){return W.aw(this.a,this.b,a,!1,H.H(this,0))},
aW:function(a,b,c){return this.U(a,null,b,c)}},
ab:{"^":"eg;a,b,c,$ti"},
ef:{"^":"a3;a,b,c,$ti",
U:function(a,b,c,d){var z,y,x,w
z=H.H(this,0)
y=this.$ti
x=new W.jH(null,new H.U(0,null,null,null,null,null,0,[[P.a3,z],[P.dQ,z]]),y)
x.a=new P.bP(null,x.gh9(x),0,null,null,null,null,y)
for(z=this.a,z=new H.cj(z,z.gj(z),0,null),w=this.c;z.u();)x.D(0,new W.eg(z.d,w,!1,y))
z=x.a
z.toString
return new P.iK(z,[H.H(z,0)]).U(a,b,c,d)},
dV:function(a){return this.U(a,null,null,null)},
aW:function(a,b,c){return this.U(a,null,b,c)}},
iZ:{"^":"dQ;a,b,c,d,e,$ti",
au:function(){if(this.b==null)return
this.dz()
this.b=null
this.d=null
return},
aY:function(a,b){if(this.b==null)return;++this.a
this.dz()},
cr:function(a){return this.aY(a,null)},
gaU:function(){return this.a>0},
cu:function(){if(this.b==null||this.a<=0)return;--this.a
this.dv()},
dv:function(){var z=this.d
if(z!=null&&this.a<=0)J.f2(this.b,this.c,z,!1)},
dz:function(){var z=this.d
if(z!=null)J.fe(this.b,this.c,z,!1)},
eX:function(a,b,c,d,e){this.dv()},
v:{
aw:function(a,b,c,d,e){var z=c==null?null:W.eH(new W.j_(c))
z=new W.iZ(0,a,b,z,!1,[e])
z.eX(a,b,c,!1,e)
return z}}},
j_:{"^":"h:0;a",
$1:[function(a){return this.a.$1(a)},null,null,2,0,null,1,"call"]},
jH:{"^":"e;a,b,$ti",
D:function(a,b){var z,y
z=this.b
if(z.a_(b))return
y=this.a
z.n(0,b,b.aW(y.gfZ(y),new W.jI(this,b),y.gh0()))},
H:function(a,b){var z=this.b.H(0,b)
if(z!=null)z.au()},
dI:[function(a){var z,y
for(z=this.b,y=z.gcG(z),y=y.gK(y);y.u();)y.gw().au()
z.ah(0)
this.a.dI(0)},"$0","gh9",0,0,1]},
jI:{"^":"h:2;a,b",
$0:function(){return this.a.H(0,this.b)}},
cy:{"^":"e;eh:a<",
as:function(a){return $.$get$em().N(0,W.aU(a))},
ag:function(a,b,c){var z,y,x
z=W.aU(a)
y=$.$get$cz()
x=y.h(0,H.b(z)+"::"+b)
if(x==null)x=y.h(0,"*::"+b)
if(x==null)return!1
return x.$4(a,b,c,this)},
f_:function(a){var z,y
z=$.$get$cz()
if(z.gJ(z)){for(y=0;y<262;++y)z.n(0,C.G[y],W.km())
for(y=0;y<12;++y)z.n(0,C.j[y],W.kn())}},
v:{
el:function(a){var z,y
z=document.createElement("a")
y=new W.jB(z,window.location)
y=new W.cy(y)
y.f_(a)
return y},
mx:[function(a,b,c,d){return!0},"$4","km",8,0,7,10,11,2,12],
my:[function(a,b,c,d){var z,y,x,w,v
z=d.geh()
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
return z},"$4","kn",8,0,7,10,11,2,12]}},
bA:{"^":"e;$ti",
gK:function(a){return new W.dj(a,this.gj(a),-1,null)},
D:function(a,b){throw H.c(new P.t("Cannot add to immutable List."))},
ay:function(a,b){throw H.c(new P.t("Cannot remove from immutable List."))},
a2:function(a,b,c,d,e){throw H.c(new P.t("Cannot setRange on immutable List."))},
$isf:1,
$asf:null,
$isj:1,
$asj:null},
dz:{"^":"e;a",
D:function(a,b){this.a.push(b)},
as:function(a){return C.a.dD(this.a,new W.hL(a))},
ag:function(a,b,c){return C.a.dD(this.a,new W.hK(a,b,c))}},
hL:{"^":"h:0;a",
$1:function(a){return a.as(this.a)}},
hK:{"^":"h:0;a,b,c",
$1:function(a){return a.ag(this.a,this.b,this.c)}},
jC:{"^":"e;eh:d<",
as:function(a){return this.a.N(0,W.aU(a))},
ag:["eO",function(a,b,c){var z,y
z=W.aU(a)
y=this.c
if(y.N(0,H.b(z)+"::"+b))return this.d.h2(c)
else if(y.N(0,"*::"+b))return this.d.h2(c)
else{y=this.b
if(y.N(0,H.b(z)+"::"+b))return!0
else if(y.N(0,"*::"+b))return!0
else if(y.N(0,H.b(z)+"::*"))return!0
else if(y.N(0,"*::*"))return!0}return!1}],
f0:function(a,b,c,d){var z,y,x
this.a.P(0,c)
z=b.cH(0,new W.jD())
y=b.cH(0,new W.jE())
this.b.P(0,z)
x=this.c
x.P(0,C.h)
x.P(0,y)}},
jD:{"^":"h:0;",
$1:function(a){return!C.a.N(C.j,a)}},
jE:{"^":"h:0;",
$1:function(a){return C.a.N(C.j,a)}},
jO:{"^":"jC;e,a,b,c,d",
ag:function(a,b,c){if(this.eO(a,b,c))return!0
if(b==="template"&&c==="")return!0
if(J.cT(a).a.getAttribute("template")==="")return this.e.N(0,b)
return!1},
v:{
es:function(){var z=P.p
z=new W.jO(P.dr(C.i,z),P.a8(null,null,null,z),P.a8(null,null,null,z),P.a8(null,null,null,z),null)
z.f0(null,new H.bk(C.i,new W.jP(),[H.H(C.i,0),null]),["TEMPLATE"],null)
return z}}},
jP:{"^":"h:0;",
$1:[function(a){return"TEMPLATE::"+H.b(a)},null,null,2,0,null,26,"call"]},
jJ:{"^":"e;",
as:function(a){var z=J.k(a)
if(!!z.$isdM)return!1
z=!!z.$isx
if(z&&W.aU(a)==="foreignObject")return!1
if(z)return!0
return!1},
ag:function(a,b,c){if(b==="is"||C.d.eA(b,"on"))return!1
return this.as(a)}},
dj:{"^":"e;a,b,c,d",
u:function(){var z,y
z=this.c+1
y=this.b
if(z<y){this.d=J.af(this.a,z)
this.c=z
return!0}this.d=null
this.c=y
return!1},
gw:function(){return this.d}},
iQ:{"^":"e;a",
dB:function(a,b,c,d){return H.y(new P.t("You can only attach EventListeners to your own window."))},
e7:function(a,b,c,d){return H.y(new P.t("You can only attach EventListeners to your own window."))},
$isO:1,
$isi:1,
v:{
iR:function(a){if(a===window)return a
else return new W.iQ(a)}}},
dy:{"^":"e;"},
jB:{"^":"e;a,b"},
et:{"^":"e;a",
cK:function(a){new W.jR(this).$2(a,null)},
aK:function(a,b){var z
if(b==null){z=a.parentNode
if(z!=null)z.removeChild(a)}else b.removeChild(a)},
fL:function(a,b){var z,y,x,w,v,u,t,s
z=!0
y=null
x=null
try{y=J.cT(a)
x=y.gfn().getAttribute("is")
w=function(c){if(!(c.attributes instanceof NamedNodeMap))return true
var r=c.childNodes
if(c.lastChild&&c.lastChild!==r[r.length-1])return true
if(c.children)if(!(c.children instanceof HTMLCollection||c.children instanceof NodeList))return true
var q=0
if(c.children)q=c.children.length
for(var p=0;p<q;p++){var o=c.children[p]
if(o.id=='attributes'||o.name=='attributes'||o.id=='lastChild'||o.name=='lastChild'||o.id=='children'||o.name=='children')return true}return false}(a)
z=w===!0?!0:!(a.attributes instanceof NamedNodeMap)}catch(t){H.C(t)}v="element unprintable"
try{v=J.A(a)}catch(t){H.C(t)}try{u=W.aU(a)
this.fK(a,b,z,v,u,y,x)}catch(t){if(H.C(t) instanceof P.ao)throw t
else{this.aK(a,b)
window
s="Removing corrupted element "+H.b(v)
if(typeof console!="undefined")console.warn(s)}}},
fK:function(a,b,c,d,e,f,g){var z,y,x,w,v
if(c){this.aK(a,b)
window
z="Removing element due to corrupted attributes on <"+d+">"
if(typeof console!="undefined")console.warn(z)
return}if(!this.a.as(a)){this.aK(a,b)
window
z="Removing disallowed element <"+H.b(e)+"> from "+J.A(b)
if(typeof console!="undefined")console.warn(z)
return}if(g!=null)if(!this.a.ag(a,"is",g)){this.aK(a,b)
window
z="Removing disallowed type extension <"+H.b(e)+' is="'+g+'">'
if(typeof console!="undefined")console.warn(z)
return}z=f.ga9()
y=H.o(z.slice(0),[H.H(z,0)])
for(x=f.ga9().length-1,z=f.a;x>=0;--x){if(x>=y.length)return H.a(y,x)
w=y[x]
if(!this.a.ag(a,J.fk(w),z.getAttribute(w))){window
v="Removing disallowed attribute <"+H.b(e)+" "+H.b(w)+'="'+H.b(z.getAttribute(w))+'">'
if(typeof console!="undefined")console.warn(v)
z.getAttribute(w)
z.removeAttribute(w)}}if(!!J.k(a).$isdU)this.cK(a.content)}},
jR:{"^":"h:15;a",
$2:function(a,b){var z,y,x,w,v,u
x=this.a
switch(a.nodeType){case 1:x.fL(a,b)
break
case 8:case 11:case 3:case 4:break
default:x.aK(a,b)}z=a.lastChild
for(x=a==null;null!=z;){y=null
try{y=J.f7(z)}catch(w){H.C(w)
v=z
if(x){u=J.m(v)
if(u.gcq(v)!=null){u.gcq(v)
u.gcq(v).removeChild(v)}}else a.removeChild(v)
z=null
y=a.lastChild}if(z!=null)this.$2(z,a)
z=y}}}}],["","",,P,{"^":"",
dd:function(){var z=$.dc
if(z==null){z=J.c_(window.navigator.userAgent,"Opera",0)
$.dc=z}return z},
fK:function(){var z,y
z=$.d9
if(z!=null)return z
y=$.da
if(y==null){y=J.c_(window.navigator.userAgent,"Firefox",0)
$.da=y}if(y)z="-moz-"
else{y=$.db
if(y==null){y=P.dd()!==!0&&J.c_(window.navigator.userAgent,"Trident/",0)
$.db=y}if(y)z="-ms-"
else z=P.dd()===!0?"-o-":"-webkit-"}$.d9=z
return z}}],["","",,P,{"^":"",ch:{"^":"i;",$isch:1,"%":"IDBKeyRange"}}],["","",,P,{"^":"",
jT:[function(a,b,c,d){var z,y,x
if(b===!0){z=[c]
C.a.P(z,d)
d=z}y=P.aF(J.cX(d,P.kA()),!0,null)
x=H.hW(a,y)
return P.ex(x)},null,null,8,0,null,27,28,29,30],
cD:function(a,b,c){var z
try{if(Object.isExtensible(a)&&!Object.prototype.hasOwnProperty.call(a,b)){Object.defineProperty(a,b,{value:c})
return!0}}catch(z){H.C(z)}return!1},
ez:function(a,b){if(Object.prototype.hasOwnProperty.call(a,b))return a[b]
return},
ex:[function(a){var z
if(a==null||typeof a==="string"||typeof a==="number"||typeof a==="boolean")return a
z=J.k(a)
if(!!z.$isbj)return a.a
if(!!z.$isc1||!!z.$isa2||!!z.$isch||!!z.$iscb||!!z.$isu||!!z.$isa1||!!z.$isbL)return a
if(!!z.$isaT)return H.P(a)
if(!!z.$isca)return P.ey(a,"$dart_jsFunction",new P.jV())
return P.ey(a,"_$dart_jsObject",new P.jW($.$get$cC()))},"$1","kB",2,0,0,13],
ey:function(a,b,c){var z=P.ez(a,b)
if(z==null){z=c.$1(a)
P.cD(a,b,z)}return z},
ew:[function(a){var z,y
if(a==null||typeof a=="string"||typeof a=="number"||typeof a=="boolean")return a
else{if(a instanceof Object){z=J.k(a)
z=!!z.$isc1||!!z.$isa2||!!z.$isch||!!z.$iscb||!!z.$isu||!!z.$isa1||!!z.$isbL}else z=!1
if(z)return a
else if(a instanceof Date){z=0+a.getTime()
y=new P.aT(z,!1)
y.cP(z,!1)
return y}else if(a.constructor===$.$get$cC())return a.o
else return P.eG(a)}},"$1","kA",2,0,19,13],
eG:function(a){if(typeof a=="function")return P.cE(a,$.$get$bx(),new P.k4())
if(a instanceof Array)return P.cE(a,$.$get$cx(),new P.k5())
return P.cE(a,$.$get$cx(),new P.k6())},
cE:function(a,b,c){var z=P.ez(a,b)
if(z==null||!(a instanceof Object)){z=c.$1(a)
P.cD(a,b,z)}return z},
bj:{"^":"e;a",
h:["eI",function(a,b){if(typeof b!=="string"&&typeof b!=="number")throw H.c(P.aR("property is not a String or num"))
return P.ew(this.a[b])}],
n:["cM",function(a,b,c){if(typeof b!=="string"&&typeof b!=="number")throw H.c(P.aR("property is not a String or num"))
this.a[b]=P.ex(c)}],
gE:function(a){return 0},
B:function(a,b){if(b==null)return!1
return b instanceof P.bj&&this.a===b.a},
k:function(a){var z,y
try{z=String(this.a)
return z}catch(y){H.C(y)
z=this.eK(this)
return z}},
bs:function(a,b){var z,y
z=this.a
y=b==null?null:P.aF(new H.bk(b,P.kB(),[H.H(b,0),null]),!0,null)
return P.ew(z[a].apply(z,y))}},
hp:{"^":"bj;a"},
hn:{"^":"hs;a,$ti",
f5:function(a){var z
if(typeof a==="number"&&Math.floor(a)===a)z=a<0||a>=this.gj(this)
else z=!1
if(z)throw H.c(P.E(a,0,this.gj(this),null,null))},
h:function(a,b){var z
if(typeof b==="number"&&b===C.c.cD(b)){if(typeof b==="number"&&Math.floor(b)===b)z=b<0||b>=this.gj(this)
else z=!1
if(z)H.y(P.E(b,0,this.gj(this),null,null))}return this.eI(0,b)},
n:function(a,b,c){var z
if(typeof b==="number"&&b===C.e.cD(b)){if(typeof b==="number"&&Math.floor(b)===b)z=b<0||b>=this.gj(this)
else z=!1
if(z)H.y(P.E(b,0,this.gj(this),null,null))}this.cM(0,b,c)},
gj:function(a){var z=this.a.length
if(typeof z==="number"&&z>>>0===z)return z
throw H.c(new P.X("Bad JsArray length"))},
sj:function(a,b){this.cM(0,"length",b)},
D:function(a,b){this.bs("push",[b])},
ay:function(a,b){this.f5(b)
return J.af(this.bs("splice",[b,1]),0)},
a2:function(a,b,c,d,e){var z,y
P.ho(b,c,this.gj(this))
z=c-b
if(z===0)return
y=[b,z]
C.a.P(y,new H.cs(d,e,null,[H.G(d,"a0",0)]).i4(0,z))
this.bs("splice",y)},
v:{
ho:function(a,b,c){if(a>c)throw H.c(P.E(a,0,c,null,null))
if(b<a||b>c)throw H.c(P.E(b,a,c,null,null))}}},
hs:{"^":"bj+a0;",$asf:null,$asj:null,$isf:1,$isj:1},
jV:{"^":"h:0;",
$1:function(a){var z=function(b,c,d){return function(){return b(c,d,this,Array.prototype.slice.apply(arguments))}}(P.jT,a,!1)
P.cD(z,$.$get$bx(),a)
return z}},
jW:{"^":"h:0;a",
$1:function(a){return new this.a(a)}},
k4:{"^":"h:0;",
$1:function(a){return new P.hp(a)}},
k5:{"^":"h:0;",
$1:function(a){return new P.hn(a,[null])}},
k6:{"^":"h:0;",
$1:function(a){return new P.bj(a)}}}],["","",,P,{"^":"",
b_:function(a,b){a=536870911&a+b
a=536870911&a+((524287&a)<<10)
return a^a>>>6},
eo:function(a){a=536870911&a+((67108863&a)<<3)
a^=a>>>11
return 536870911&a+((16383&a)<<15)},
a9:{"^":"e;q:a>,t:b>,$ti",
k:function(a){return"Point("+H.b(this.a)+", "+H.b(this.b)+")"},
B:function(a,b){var z,y
if(b==null)return!1
if(!(b instanceof P.a9))return!1
z=this.a
y=b.a
if(z==null?y==null:z===y){z=this.b
y=b.b
y=z==null?y==null:z===y
z=y}else z=!1
return z},
gE:function(a){var z,y
z=J.T(this.a)
y=J.T(this.b)
return P.eo(P.b_(P.b_(0,z),y))},
i:function(a,b){var z,y,x,w
z=this.a
y=J.m(b)
x=y.gq(b)
if(typeof z!=="number")return z.i()
if(typeof x!=="number")return H.d(x)
w=this.b
y=y.gt(b)
if(typeof w!=="number")return w.i()
if(typeof y!=="number")return H.d(y)
return new P.a9(z+x,w+y,this.$ti)},
G:function(a,b){var z,y,x,w
z=this.a
y=J.m(b)
x=y.gq(b)
if(typeof z!=="number")return z.G()
if(typeof x!=="number")return H.d(x)
w=this.b
y=y.gt(b)
if(typeof w!=="number")return w.G()
if(typeof y!=="number")return H.d(y)
return new P.a9(z-x,w-y,this.$ti)},
C:function(a,b){var z,y
z=this.a
if(typeof z!=="number")return z.C()
if(typeof b!=="number")return H.d(b)
y=this.b
if(typeof y!=="number")return y.C()
return new P.a9(z*b,y*b,this.$ti)}},
jw:{"^":"e;$ti",
gcv:function(a){var z,y
z=this.a
y=this.c
if(typeof z!=="number")return z.i()
if(typeof y!=="number")return H.d(y)
return z+y},
gcd:function(a){var z,y
z=this.b
y=this.d
if(typeof z!=="number")return z.i()
if(typeof y!=="number")return H.d(y)
return z+y},
k:function(a){return"Rectangle ("+H.b(this.a)+", "+H.b(this.b)+") "+H.b(this.c)+" x "+H.b(this.d)},
B:function(a,b){var z,y,x,w
if(b==null)return!1
z=J.k(b)
if(!z.$isam)return!1
y=this.a
x=z.gaV(b)
if(y==null?x==null:y===x){x=this.b
w=z.gb1(b)
if(x==null?w==null:x===w){w=this.c
if(typeof y!=="number")return y.i()
if(typeof w!=="number")return H.d(w)
if(y+w===z.gcv(b)){y=this.d
if(typeof x!=="number")return x.i()
if(typeof y!=="number")return H.d(y)
z=x+y===z.gcd(b)}else z=!1}else z=!1}else z=!1
return z},
gE:function(a){var z,y,x,w,v,u
z=this.a
y=J.T(z)
x=this.b
w=J.T(x)
v=this.c
if(typeof z!=="number")return z.i()
if(typeof v!=="number")return H.d(v)
u=this.d
if(typeof x!=="number")return x.i()
if(typeof u!=="number")return H.d(u)
return P.eo(P.b_(P.b_(P.b_(P.b_(0,y),w),z+v&0x1FFFFFFF),x+u&0x1FFFFFFF))},
gcF:function(a){return new P.a9(this.a,this.b,this.$ti)}},
am:{"^":"jw;aV:a>,b1:b>,m:c>,p:d>,$ti",$asam:null,v:{
i7:function(a,b,c,d,e){var z,y
if(typeof c!=="number")return c.X()
if(c<0)z=-c*0
else z=c
if(typeof d!=="number")return d.X()
if(d<0)y=-d*0
else y=d
return new P.am(a,b,z,y,[e])}}}}],["","",,P,{"^":"",kR:{"^":"aE;",$isi:1,"%":"SVGAElement"},kT:{"^":"x;",$isi:1,"%":"SVGAnimateElement|SVGAnimateMotionElement|SVGAnimateTransformElement|SVGAnimationElement|SVGSetElement"},l4:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEBlendElement"},l5:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEColorMatrixElement"},l6:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEComponentTransferElement"},l7:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFECompositeElement"},l8:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEConvolveMatrixElement"},l9:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEDiffuseLightingElement"},la:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEDisplacementMapElement"},lb:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEFloodElement"},lc:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEGaussianBlurElement"},ld:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEImageElement"},le:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEMergeElement"},lf:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEMorphologyElement"},lg:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFEOffsetElement"},lh:{"^":"x;q:x=,t:y=","%":"SVGFEPointLightElement"},li:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFESpecularLightingElement"},lj:{"^":"x;q:x=,t:y=","%":"SVGFESpotLightElement"},lk:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFETileElement"},ll:{"^":"x;p:height=,I:result=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFETurbulenceElement"},ln:{"^":"x;p:height=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGFilterElement"},lo:{"^":"aE;p:height=,m:width=,q:x=,t:y=","%":"SVGForeignObjectElement"},fU:{"^":"aE;","%":"SVGCircleElement|SVGEllipseElement|SVGLineElement|SVGPathElement|SVGPolygonElement|SVGPolylineElement;SVGGeometryElement"},aE:{"^":"x;",$isi:1,"%":"SVGClipPathElement|SVGDefsElement|SVGGElement|SVGSwitchElement;SVGGraphicsElement"},ls:{"^":"aE;p:height=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGImageElement"},aV:{"^":"i;",$ise:1,"%":"SVGLength"},lB:{"^":"h4;",
gj:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.as(b,a,null,null,null))
return a.getItem(b)},
n:function(a,b,c){throw H.c(new P.t("Cannot assign element of immutable List."))},
sj:function(a,b){throw H.c(new P.t("Cannot resize immutable List."))},
O:function(a,b){return this.h(a,b)},
$isf:1,
$asf:function(){return[P.aV]},
$isj:1,
$asj:function(){return[P.aV]},
"%":"SVGLengthList"},h0:{"^":"i+a0;",
$asf:function(){return[P.aV]},
$asj:function(){return[P.aV]},
$isf:1,
$isj:1},h4:{"^":"h0+bA;",
$asf:function(){return[P.aV]},
$asj:function(){return[P.aV]},
$isf:1,
$isj:1},lF:{"^":"x;",$isi:1,"%":"SVGMarkerElement"},lG:{"^":"x;p:height=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGMaskElement"},aY:{"^":"i;",$ise:1,"%":"SVGNumber"},lY:{"^":"h5;",
gj:function(a){return a.length},
h:function(a,b){if(b>>>0!==b||b>=a.length)throw H.c(P.as(b,a,null,null,null))
return a.getItem(b)},
n:function(a,b,c){throw H.c(new P.t("Cannot assign element of immutable List."))},
sj:function(a,b){throw H.c(new P.t("Cannot resize immutable List."))},
O:function(a,b){return this.h(a,b)},
$isf:1,
$asf:function(){return[P.aY]},
$isj:1,
$asj:function(){return[P.aY]},
"%":"SVGNumberList"},h1:{"^":"i+a0;",
$asf:function(){return[P.aY]},
$asj:function(){return[P.aY]},
$isf:1,
$isj:1},h5:{"^":"h1+bA;",
$asf:function(){return[P.aY]},
$asj:function(){return[P.aY]},
$isf:1,
$isj:1},m2:{"^":"x;p:height=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGPatternElement"},m6:{"^":"fU;p:height=,m:width=,q:x=,t:y=","%":"SVGRectElement"},dM:{"^":"x;",$isdM:1,$isi:1,"%":"SVGScriptElement"},x:{"^":"aq;",
sdS:function(a,b){this.bE(a,b)},
T:function(a,b,c,d){var z,y,x,w,v,u
z=H.o([],[W.dy])
z.push(W.el(null))
z.push(W.es())
z.push(new W.jJ())
c=new W.et(new W.dz(z))
y='<svg version="1.1">'+H.b(b)+"</svg>"
z=document
x=z.body
w=(x&&C.l).hc(x,y,c)
v=z.createDocumentFragment()
w.toString
z=new W.a4(w)
u=z.gao(z)
for(;z=u.firstChild,z!=null;)v.appendChild(z)
return v},
dL:function(a){return a.focus()},
gdZ:function(a){return new W.ab(a,"change",!1,[W.a2])},
ge_:function(a){return new W.ab(a,"input",!1,[W.a2])},
ge0:function(a){return new W.ab(a,"mousedown",!1,[W.au])},
ge1:function(a){return new W.ab(a,"mousemove",!1,[W.au])},
ge2:function(a){return new W.ab(a,"mouseup",!1,[W.au])},
$isx:1,
$isO:1,
$isi:1,
"%":"SVGComponentTransferFunctionElement|SVGDescElement|SVGDiscardElement|SVGFEDistantLightElement|SVGFEFuncAElement|SVGFEFuncBElement|SVGFEFuncGElement|SVGFEFuncRElement|SVGFEMergeNodeElement|SVGMetadataElement|SVGStopElement|SVGStyleElement|SVGTitleElement;SVGElement"},mc:{"^":"aE;p:height=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGSVGElement"},md:{"^":"x;",$isi:1,"%":"SVGSymbolElement"},dV:{"^":"aE;","%":";SVGTextContentElement"},mi:{"^":"dV;",$isi:1,"%":"SVGTextPathElement"},mj:{"^":"dV;q:x=,t:y=","%":"SVGTSpanElement|SVGTextElement|SVGTextPositioningElement"},ml:{"^":"aE;p:height=,m:width=,q:x=,t:y=",$isi:1,"%":"SVGUseElement"},mn:{"^":"x;",$isi:1,"%":"SVGViewElement"},mv:{"^":"x;",$isi:1,"%":"SVGGradientElement|SVGLinearGradientElement|SVGRadialGradientElement"},mA:{"^":"x;",$isi:1,"%":"SVGCursorElement"},mB:{"^":"x;",$isi:1,"%":"SVGFEDropShadowElement"},mC:{"^":"x;",$isi:1,"%":"SVGMPathElement"}}],["","",,P,{"^":""}],["","",,P,{"^":"",m7:{"^":"i;",$isi:1,"%":"WebGL2RenderingContext"}}],["","",,P,{"^":""}],["","",,U,{"^":"",
fw:function(a,b){var z
if($.bb==null){z=new H.U(0,null,null,null,null,null,0,[P.p,U.c5])
$.bb=z
z.n(0,"NetLogo",new U.hH("  "))
$.bb.n(0,"plain",new U.hT("  "))}if($.bb.a_(a))return $.bb.h(0,a).d9(b)
else return C.p.hp(b)},
lv:[function(a,b){var z,y
if($.$get$aM().h(0,a) instanceof U.d5){z=$.$get$aM().h(0,a)
C.a.sj(z.a,0)
C.a.sj(z.r,0)
C.a.H(z.ch.c,z)}y=C.p.hd(b)
if(!!J.k(y).$isV){$.$get$aM().n(0,a,U.fx(a,y))
$.$get$aM().h(0,a).a8()}},"$2","kF",4,0,20,14,31],
lu:[function(a,b){if($.$get$aM().a_(a))return U.fw(b,$.$get$aM().h(0,a).ci())
return},"$2","kE",4,0,21,14,32],
mK:[function(){var z=$.$get$cJ()
J.bZ(z,"NetTango_InitWorkspace",U.kF())
J.bZ(z,"NetTango_ExportCode",U.kE())},"$0","eV",0,0,1],
cP:function(a,b){var z,y
if(a==null)return b
else if(typeof a==="number"&&Math.floor(a)===a)return a
else if(typeof a==="string")try{z=H.dI(a,null,null)
return z}catch(y){if(!!J.k(H.C(y)).$isby)return b
else throw y}return b},
an:function(a,b){var z,y
if(a==null)return b
else if(typeof a==="number")return a
else if(typeof a==="string")try{z=P.kH(a,null)
return z}catch(y){if(!!J.k(H.C(y)).$isby)return b
else throw y}return b},
bs:function(a,b){if(a==null)return b
else if(typeof a==="boolean")return a
else if(typeof a==="string")if(a.toLowerCase()==="true"||a.toLowerCase()==="t")return!0
else if(a.toLowerCase()==="false"||a.toLowerCase()==="f")return!1
return b},
ba:{"^":"e;a,cb:b>,c,d,q:e*,t:f*,m:r>,x,R:y@,bz:z@,dR:Q<,ch,e3:cx<,e6:cy<,db,dx,dy,fr,fx,fy,dP:go<,d5:id<,k1,k2,k3,k4,dg:r1<,dA:r2<",
gp:function(a){return this.r1?$.$get$n():this.x},
gaR:function(){return 0},
gax:function(){return 0},
gaQ:function(){return this.y!=null},
ghF:function(){return this.z!=null},
gb2:function(){return this.f},
gh7:function(){var z,y
z=this.f
y=this.r1?$.$get$n():this.x
if(typeof z!=="number")return z.i()
if(typeof y!=="number")return H.d(y)
return z+y},
gaM:function(){var z=this.y
return z!=null?z.gaM():this},
gbx:function(){var z=this.y
if(!(z!=null)){z=this.ch
z=z!=null?z.rx:null}return z},
gdU:function(){return this.z==null},
av:function(a){var z=U.fo(this.fy,this.b)
this.bS(z)
return z},
bS:function(a){var z,y,x,w
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
for(z=this.cx,y=z.length,x=a.cx,w=0;w<z.length;z.length===y||(0,H.z)(z),++w)x.push(J.cR(z[w],a))
for(z=this.cy,y=z.length,x=a.cy,w=0;w<z.length;z.length===y||(0,H.z)(z),++w)x.push(J.cR(z[w],a))},
W:function(){var z,y,x,w,v,u
z=P.bC()
z.n(0,"id",this.a)
z.n(0,"action",this.b)
z.n(0,"type",this.c)
z.n(0,"format",this.d)
z.n(0,"start",this.go)
z.n(0,"required",this.fx)
y=this.cx
if(y.length!==0){z.n(0,"params",[])
for(x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w){v=y[w]
J.aA(z.h(0,"params"),v.W())}}y=this.cy
if(y.length!==0){z.n(0,"properties",[])
for(x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w){u=y[w]
J.aA(z.h(0,"properties"),u.W())}}return z},
ci:function(){var z=[]
this.Z(z)
return z},
Z:function(a){var z
J.aA(a,this.W())
z=this.y
if(z!=null)z.Z(a)},
c7:function(a,b){var z,y,x,w,v,u,t,s,r
z=$.$get$a5()
y=this.da(a)
x=$.$get$M()
if(typeof x!=="number")return x.C()
if(typeof y!=="number")return y.i()
this.r=Math.max(H.eN(z),y+x*2)
if(!this.r1&&this.cx.length!==0)for(z=this.cx,y=z.length,w=0,v=0;v<z.length;z.length===y||(0,H.z)(z),++v){u=z[v]
u.bn(a)
t=J.v(J.cV(u),x)
if(typeof t!=="number")return H.d(t)
w+=t}else w=0
if(!this.r1&&this.cy.length!==0)for(z=this.cy,y=z.length,s=0,v=0;v<z.length;z.length===y||(0,H.z)(z),++v)s=Math.max(s,z[v].fJ(a))
else s=0
z=this.e
if(typeof z!=="number")return z.i()
y=this.r
if(typeof y!=="number")return H.d(y)
y=Math.max(z+s,z+y+w)
b=Math.max(H.eN(b),y)
r=this.gbx()
if(r!=null)b=r.c7(a,b)
z=this.e
if(typeof z!=="number")return H.d(z)
this.r=b-z
return b},
a4:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a4(a+this.gax(),b)},
bm:["eD",function(){var z,y,x,w,v
z=this.y
if(z!=null){y=this.f
x=this.r1?$.$get$n():this.x
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
J.fj(z,y+x)
x=this.y
y=this.e
z=x.gdR()
w=this.Q
if(typeof z!=="number")return z.G()
v=$.$get$ap()
if(typeof v!=="number")return H.d(v)
if(typeof y!=="number")return y.i()
J.fi(x,y+(z-w)*v)
this.y.bm()}}],
da:function(a){var z,y
z=J.m(a)
z.S(a)
z.saw(a,this.fr)
y=z.cn(a,this.b).width
z.V(a)
return y},
br:function(a){var z,y,x,w,v
z=this.id
if(z){y=this.e
x=this.k1
w=this.k3
if(typeof x!=="number")return x.G()
if(typeof w!=="number")return H.d(w)
if(typeof y!=="number")return y.i()
this.e=y+(x-w)
w=this.f
y=this.k2
v=this.k4
if(typeof y!=="number")return y.G()
if(typeof v!=="number")return H.d(v)
if(typeof w!=="number")return w.i()
this.f=w+(y-v)
this.k3=x
this.k4=y}return z},
bU:function(a){var z,y,x,w,v,u
z=J.m(a)
z.S(a)
z.sak(a,this.dx)
z.saw(a,this.fr)
z.scB(a,"left")
z.scC(a,"middle")
y=this.b
x=this.e
w=$.$get$M()
if(typeof x!=="number")return x.i()
if(typeof w!=="number")return H.d(w)
v=this.f
u=$.$get$n()
if(typeof u!=="number")return u.aA()
if(typeof v!=="number")return v.i()
z.ck(a,y,x+w,v+u/2)
z.V(a)},
bV:function(a){var z,y
z=J.m(a)
z.S(a)
this.c4(a)
z.sbH(a,this.dy)
y=$.$get$Q()
if(typeof y!=="number")return H.d(y)
z.scm(a,0.5*y)
z.shQ(a,"round")
z.bG(a)
z.V(a)},
bT:function(a){var z=J.m(a)
z.S(a)
this.c4(a)
z.sak(a,this.db)
z.cj(a)
z.sak(a,"rgba(0, 0, 0, "+H.b(Math.min(1,0.075*this.Q)))
z.cj(a)
z.V(a)},
fd:function(a){var z,y,x,w,v
z=J.m(a)
z.S(a)
z.scm(a,5)
z.sbH(a,this.dy)
z.at(a)
y=this.e
x=$.$get$M()
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
w=$.$get$ap()
v=this.gaR()
if(typeof w!=="number")return w.C()
z.aX(a,y+x+w*v,this.f)
this.c6(a,this.z==null&&this.go)
z.bG(a)
z.V(a)},
fa:function(a){var z,y,x,w,v,u
z=J.m(a)
z.S(a)
z.scm(a,5)
z.sbH(a,this.dy)
z.at(a)
y=this.e
x=this.r
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
w=$.$get$M()
if(typeof w!=="number")return H.d(w)
v=this.f
u=this.r1?$.$get$n():this.x
if(typeof v!=="number")return v.i()
if(typeof u!=="number")return H.d(u)
z.aX(a,y+x-w,v+u)
this.c5(a,this.y==null&&this.Q===0)
z.bG(a)
z.V(a)},
fb:function(a){var z,y,x,w,v
z=this.r
for(y=this.cx,x=y.length-1;x>=0;--x){w=$.$get$M()
if(x>=y.length)return H.a(y,x)
v=J.cV(y[x])
if(typeof w!=="number")return w.i()
if(typeof v!=="number")return H.d(v)
if(typeof z!=="number")return z.G()
z-=w+v
if(x>=y.length)return H.a(y,x)
y[x].cg(a,z)}},
fc:function(a){var z,y,x,w
for(z=this.cy,y=0;y<z.length;y=w){x=$.$get$n()
w=y+1
if(typeof x!=="number")return x.C()
z[y].ho(a,x*w)}},
c4:["eC",function(a){var z,y,x,w,v,u
z=J.m(a)
z.at(a)
y=this.e
x=$.$get$M()
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
z.aX(a,y+x,this.f)
this.c6(a,this.z==null&&this.go)
y=this.Q===0
w=y&&this.z==null
this.dk(a,w,y&&this.y==null)
this.c5(a,this.y==null&&this.Q===0)
if(this.Q<=0)y=this.z!=null&&this.y!=null
else y=!0
if(y){y=this.e
w=this.f
v=this.r1?$.$get$n():this.x
if(typeof w!=="number")return w.i()
if(typeof v!=="number")return H.d(v)
z.A(a,y,w+v)
z.A(a,this.e,this.f)
v=this.e
if(typeof v!=="number")return v.i()
z.A(a,v+x,this.f)}else if(this.y!=null){y=this.e
w=this.f
v=this.r1?$.$get$n():this.x
if(typeof w!=="number")return w.i()
if(typeof v!=="number")return H.d(v)
z.A(a,y,w+v)
v=this.e
w=this.f
if(typeof w!=="number")return w.i()
z.A(a,v,w+x)
w=this.e
v=this.f
if(typeof w!=="number")return w.i()
z.M(a,w,v,w+x,v)}else{y=this.z
w=this.e
v=this.f
if(y!=null){y=this.r1
u=y?$.$get$n():this.x
if(typeof v!=="number")return v.i()
if(typeof u!=="number")return H.d(u)
y=y?$.$get$n():this.x
if(typeof y!=="number")return H.d(y)
z.M(a,w,v+u,w,v+y-x)
z.A(a,this.e,this.f)
y=this.e
if(typeof y!=="number")return y.i()
z.A(a,y+x,this.f)}else{y=this.r1
u=y?$.$get$n():this.x
if(typeof v!=="number")return v.i()
if(typeof u!=="number")return H.d(u)
y=y?$.$get$n():this.x
if(typeof y!=="number")return H.d(y)
z.M(a,w,v+u,w,v+y-x)
y=this.e
v=this.f
if(typeof v!=="number")return v.i()
z.A(a,y,v+x)
v=this.e
y=this.f
if(typeof v!=="number")return v.i()
z.M(a,v,y,v+x,y)}}z.ce(a)}],
dk:function(a,b,c){var z,y,x,w,v,u
z=$.$get$M()
y=this.e
x=this.r
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
if(typeof z!=="number")return H.d(z)
w=J.m(a)
w.A(a,y+x-z,this.f)
if(b&&c){y=this.e
x=this.r
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
x=y+x
y=this.f
if(typeof y!=="number")return y.i()
w.M(a,x,y,x,y+z)
y=this.e
x=this.r
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
v=this.f
u=this.r1?$.$get$n():this.x
if(typeof v!=="number")return v.i()
if(typeof u!=="number")return H.d(u)
w.A(a,y+x,v+u-z)
u=this.e
v=this.r
if(typeof u!=="number")return u.i()
if(typeof v!=="number")return H.d(v)
v=u+v
u=this.f
y=this.r1
x=y?$.$get$n():this.x
if(typeof u!=="number")return u.i()
if(typeof x!=="number")return H.d(x)
y=y?$.$get$n():this.x
if(typeof y!=="number")return H.d(y)
w.M(a,v,u+x,v-z,u+y)}else if(c){y=this.e
x=this.r
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
w.A(a,y+x,this.f)
x=this.e
y=this.r
if(typeof x!=="number")return x.i()
if(typeof y!=="number")return H.d(y)
v=this.f
u=this.r1?$.$get$n():this.x
if(typeof v!=="number")return v.i()
if(typeof u!=="number")return H.d(u)
w.A(a,x+y,v+u-z)
u=this.e
v=this.r
if(typeof u!=="number")return u.i()
if(typeof v!=="number")return H.d(v)
v=u+v
u=this.f
y=this.r1
x=y?$.$get$n():this.x
if(typeof u!=="number")return u.i()
if(typeof x!=="number")return H.d(x)
y=y?$.$get$n():this.x
if(typeof y!=="number")return H.d(y)
w.M(a,v,u+x,v-z,u+y)}else{y=this.e
x=this.r
v=this.f
if(b){if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
y+=x
if(typeof v!=="number")return v.i()
w.M(a,y,v,y,v+z)
v=this.e
y=this.r
if(typeof v!=="number")return v.i()
if(typeof y!=="number")return H.d(y)
x=this.f
u=this.r1?$.$get$n():this.x
if(typeof x!=="number")return x.i()
if(typeof u!=="number")return H.d(u)
w.A(a,v+y,x+u)
u=this.e
x=this.r
if(typeof u!=="number")return u.i()
if(typeof x!=="number")return H.d(x)
y=this.f
v=this.r1?$.$get$n():this.x
if(typeof y!=="number")return y.i()
if(typeof v!=="number")return H.d(v)
w.A(a,u+x-z,y+v)}else{if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
w.A(a,y+x,v)
y=this.e
x=this.r
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
v=this.f
u=this.r1?$.$get$n():this.x
if(typeof v!=="number")return v.i()
if(typeof u!=="number")return H.d(u)
w.A(a,y+x,v+u)
u=this.e
v=this.r
if(typeof u!=="number")return u.i()
if(typeof v!=="number")return H.d(v)
x=this.f
y=this.r1?$.$get$n():this.x
if(typeof x!=="number")return x.i()
if(typeof y!=="number")return H.d(y)
w.A(a,u+v-z,x+y)}}},
c6:function(a,b){var z,y,x,w,v,u
z=$.$get$M()
y=this.e
if(typeof z!=="number")return z.C()
if(typeof y!=="number")return y.i()
x=$.$get$ap()
w=this.gaR()
if(typeof x!=="number")return x.C()
v=y+z*2+x*w
if(b){y=J.m(a)
y.A(a,v,this.f)
x=this.f
if(typeof x!=="number")return x.i()
w=x+z/2
u=v+z
y.dE(a,v,w,u,w,u,x)}y=this.e
x=this.r
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
J.cW(a,y+x-z,this.f)},
c5:function(a,b){var z,y,x,w,v,u,t,s,r
z=$.$get$M()
y=this.e
if(typeof z!=="number")return z.C()
if(typeof y!=="number")return y.i()
x=y+z*2
if(!this.r1){y=$.$get$ap()
w=this.gax()
if(typeof y!=="number")return y.C()
x+=y*w}if(b){y=x+z
w=this.f
v=this.r1?$.$get$n():this.x
if(typeof w!=="number")return w.i()
if(typeof v!=="number")return H.d(v)
u=J.m(a)
u.A(a,y,w+v)
v=this.f
w=this.r1
t=w?$.$get$n():this.x
if(typeof v!=="number")return v.i()
if(typeof t!=="number")return H.d(t)
s=z/2
r=w?$.$get$n():this.x
if(typeof r!=="number")return H.d(r)
w=w?$.$get$n():this.x
if(typeof w!=="number")return H.d(w)
u.dE(a,y,v+t+s,x,v+r+s,x,v+w)}y=this.f
w=this.r1?$.$get$n():this.x
if(typeof y!=="number")return y.i()
if(typeof w!=="number")return H.d(w)
J.cW(a,x-z,y+w)},
bu:function(a){var z,y,x,w,v,u
z=a.c
y=a.d
x=this.f
w=this.r1?$.$get$n():this.x
if(typeof x!=="number")return x.i()
if(typeof w!=="number")return H.d(w)
v=this.e
if(typeof v!=="number")return H.d(v)
if(z>=v)if(y>=x){u=this.r
if(typeof u!=="number")return H.d(u)
w=z<=v+u&&y<=x+w}else w=!1
else w=!1
return w},
aa:function(a){var z,y,x
this.id=!0
z=a.c
this.k1=z
y=a.d
this.k2=y
this.k3=z
this.k4=y
z=this.z
if(z!=null){z.sR(null)
this.z=null}for(z=this.fy,x=this;x!=null;){z.fG(x)
z.bK(x)
x=x.gbx()}return this},
b5:function(a){var z
this.id=!1
this.r1=!1
this.r2=!1
z=this.fy
z.fX(this)
z.fT(this)
z.e5()},
b3:function(a){this.k1=a.c
this.k2=a.d},
b4:function(a){},
b8:function(a,b){var z=$.a6
$.a6=z+1
this.a=z
this.r=$.$get$a5()
this.x=$.$get$n()},
v:{
fo:function(a,b){var z,y,x
z=[U.ak]
y=H.o([],z)
z=H.o([],z)
x=$.$get$Q()
if(typeof x!=="number")return H.d(x)
x=new U.ba(null,b,null,null,0,0,0,0,null,null,0,null,y,z,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*x)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
x.b8(a,b)
return x},
d0:function(a,b){var z,y,x,w,v,u,t,s,r,q
z=J.B(b)
y=z.h(b,"action")
x=y==null?"":J.A(y)
if(!!J.k(z.h(b,"clauses")).$isf){y=H.o([],[U.aC])
w=[U.ak]
v=H.o([],w)
u=H.o([],w)
t=$.$get$Q()
if(typeof t!=="number")return H.d(t)
t=14*t
s=new U.b9(y,null,null,null,x,null,null,0,0,0,0,null,null,0,null,v,u,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(t)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
u=$.a6
$.a6=u+1
s.a=u
u=$.$get$a5()
s.r=u
v=$.$get$n()
s.x=v
t=new U.c8(null,null,null,"end-"+H.b(x),null,null,0,0,0,0,null,null,0,null,H.o([],w),H.o([],w),"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(t)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w=$.a6
$.a6=w+1
t.a=w
t.r=u
t.x=v
t.go=!1
if(typeof v!=="number")return v.aA()
t.x=v/2
s.x1=t
t.ry=s
y.push(t)
s.rx=s.x1}else{y=[U.ak]
if(J.N(z.h(b,"type"),"clause")){w=H.o([],y)
y=H.o([],y)
v=$.$get$Q()
if(typeof v!=="number")return H.d(v)
s=new U.aC(null,null,null,x,null,null,0,0,0,0,null,null,0,null,w,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
v=$.a6
$.a6=v+1
s.a=v
s.r=$.$get$a5()
s.x=$.$get$n()
s.go=!1}else{w=H.o([],y)
y=H.o([],y)
v=$.$get$Q()
if(typeof v!=="number")return H.d(v)
s=new U.ba(null,x,null,null,0,0,0,0,null,null,0,null,w,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
v=$.a6
$.a6=v+1
s.a=v
s.r=$.$get$a5()
s.x=$.$get$n()}}y=z.h(b,"type")
s.c=y==null?"":J.A(y)
y=z.h(b,"format")
s.d=y==null?null:J.A(y)
y=z.h(b,"blockColor")
w=s.db
s.db=y==null?w:J.A(y)
y=z.h(b,"textColor")
w=s.dx
s.dx=y==null?w:J.A(y)
y=z.h(b,"borderColor")
w=s.dy
s.dy=y==null?w:J.A(y)
y=z.h(b,"font")
w=s.fr
s.fr=y==null?w:J.A(y)
s.go=!U.bs(z.h(b,"start"),!1)
s.fx=U.bs(z.h(b,"required"),s.fx)
if(!!J.k(z.h(b,"params")).$isf)for(y=J.L(z.h(b,"params")),w=s.cx;y.u();)w.push(U.cp(s,y.gw()))
if(!!J.k(z.h(b,"properties")).$isf)for(y=J.L(z.h(b,"properties")),w=s.cy;y.u();)w.push(U.cp(s,y.gw()))
y=s.cy.length
w=$.$get$n()
if(typeof w!=="number")return H.d(w)
s.x=(1+y)*w
if(!!s.$isb9&&!!J.k(z.h(b,"clauses")).$isf)for(z=J.L(z.h(b,"clauses"));z.u();){r=z.gw()
J.bZ(r,"type","clause")
q=H.eR(U.d0(a,r),"$isaC")
H.eR(s,"$isb9").cR(q)}return s}}},
d7:{"^":"ba;co:rx@",
gbx:function(){var z=this.y
if(z!=null)return z
else{z=this.rx
if(z!=null)return z
else{z=this.ch
if(z!=null)return z.rx
else return}}},
a4:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a4(a+this.gax(),this)},
fw:function(a){var z,y,x,w,v,u,t
z=$.$get$M()
if(this.rx!=null){y=this.e
x=$.$get$ap()
if(typeof y!=="number")return y.i()
if(typeof x!=="number")return H.d(x)
y+=x
w=this.f
v=this.r1
u=v?$.$get$n():this.x
if(typeof w!=="number")return w.i()
if(typeof u!=="number")return H.d(u)
v=v?$.$get$n():this.x
if(typeof v!=="number")return H.d(v)
if(typeof z!=="number")return H.d(z)
t=J.m(a)
t.M(a,y,w+u,y,w+v+z)
y=this.y
w=this.e
v=this.rx
if(y!=null){if(typeof w!=="number")return w.i()
t.A(a,w+x,J.b8(v))
y=this.e
if(typeof y!=="number")return y.i()
t.A(a,y+x+z,J.b8(this.rx))}else{if(typeof w!=="number")return w.i()
t.A(a,w+x,J.D(J.b8(v),z))
y=this.e
if(typeof y!=="number")return y.i()
w=J.b8(this.rx)
v=this.e
if(typeof v!=="number")return v.i()
t.M(a,y+x,w,v+x+z,J.b8(this.rx))}}}},
aC:{"^":"d7;h5:ry?,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gaR:function(){return 1},
gax:function(){return 1},
gdU:function(){return!1},
av:function(a){var z,y,x,w,v,u
z=this.fy
y=this.b
x=[U.ak]
w=H.o([],x)
x=H.o([],x)
v=$.$get$Q()
if(typeof v!=="number")return H.d(v)
u=new U.aC(null,null,null,y,null,null,0,0,0,0,null,null,0,null,w,x,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*v)+"px 'Poppins', sans-serif",!1,z,!0,!1,null,null,null,null,!1,!0)
u.b8(z,y)
u.go=!1
this.bS(u)
return u},
Z:function(a){var z,y
z=this.W()
z.n(0,"children",[])
J.aA(a,z)
y=this.y
if(y!=null)y.Z(z.h(0,"children"))},
bV:function(a){},
bT:function(a){},
aa:function(a){return this.ry.aa(a)}},
c8:{"^":"aC;ry,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gaR:function(){return 1},
gax:function(){return 0},
a4:function(a,b){var z
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a4(a,b)},
Z:function(a){},
bU:function(a){}},
b9:{"^":"d7;ry,x1,rx,a,b,c,d,e,f,r,x,y,z,Q,ch,cx,cy,db,dx,dy,fr,fx,fy,go,id,k1,k2,k3,k4,r1,r2",
gaR:function(){return 0},
gax:function(){return 1},
av:function(a){var z,y,x,w,v,u
z=U.fn(this.fy,this.b)
this.bS(z)
for(y=this.ry,x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w){v=y[w]
u=J.k(v)
if(!u.$isc8)z.cR(u.av(v))}return z},
gaM:function(){var z,y
z=this.x1
y=z.y
return y!=null?y.gaM():z},
Z:function(a){var z,y,x,w
z=this.W()
z.n(0,"children",[])
z.n(0,"clauses",[])
J.aA(a,z)
y=this.y
if(y!=null)y.Z(z.h(0,"children"))
for(y=this.ry,x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w)y[w].Z(z.h(0,"clauses"))
y=this.x1.y
if(y!=null)y.Z(a)},
a4:function(a,b){var z,y,x
this.Q=a
this.ch=b
z=this.y
if(z!=null)z.a4(a+1,this)
for(z=this.ry,y=z.length,x=0;x<z.length;z.length===y||(0,H.z)(z),++x)z[x].a4(a,b)},
bm:function(){var z,y,x,w,v,u,t,s,r
this.eD()
for(z=this.ry,y=z.length,x=this,w=0;w<z.length;z.length===y||(0,H.z)(z),++w,x=v){v=z[w]
u=J.m(v)
if(x.gaQ()){t=x.gR().gaM()
u.sq(v,this.e)
s=t.f
r=t.r1?$.$get$n():t.x
if(typeof s!=="number")return s.i()
if(typeof r!=="number")return H.d(r)
u.st(v,s+r)}else{u.sq(v,this.e)
s=J.m(x)
s=J.v(s.gt(x),s.gp(x))
r=$.$get$n()
if(typeof r!=="number")return H.d(r)
u.st(v,s+r)}v.bm()}},
cR:function(a){var z,y,x,w
a.sh5(this)
z=this.ry
C.a.H(z,this.x1)
z.push(a)
z.push(this.x1)
for(y=0;x=z.length,y<x-1;y=w){w=y+1
z[y].sco(z[w])}if(0>=x)return H.a(z,0)
this.rx=z[0]},
c4:function(a){var z,y,x,w,v,u,t,s,r,q
if(this.r1){this.eC(a)
return}z=$.$get$M()
y=J.m(a)
y.at(a)
x=this.e
if(typeof x!=="number")return x.i()
if(typeof z!=="number")return H.d(z)
y.aX(a,x+z,this.f)
w=this.z==null&&this.go
for(v=this;v!=null;){if(!v.gaQ())u=v.gco()!=null||this.Q===0
else u=!1
v.c6(a,w)
v.dk(a,w,u)
v.c5(a,u)
v.fw(a)
w=!v.gaQ()
v=v.gco()}x=this.x1
t=x.y!=null||this.Q>0
s=this.e
r=x.f
if(t){x=x.r1?$.$get$n():x.x
if(typeof r!=="number")return r.i()
if(typeof x!=="number")return H.d(x)
y.A(a,s,r+x)}else{if(typeof s!=="number")return s.i()
x=x.r1?$.$get$n():x.x
if(typeof r!=="number")return r.i()
if(typeof x!=="number")return H.d(x)
y.A(a,s+z,r+x)
x=this.e
r=this.x1
s=r.f
t=r.r1
q=t?$.$get$n():r.x
if(typeof s!=="number")return s.i()
if(typeof q!=="number")return H.d(q)
t=t?$.$get$n():r.x
if(typeof t!=="number")return H.d(t)
y.M(a,x,s+q,x,s+t-z)}x=this.z
t=this.e
s=this.f
if(x!=null){y.A(a,t,s)
x=this.e
if(typeof x!=="number")return x.i()
y.A(a,x+z,this.f)}else{if(typeof s!=="number")return s.i()
y.A(a,t,s+z)
x=this.e
t=this.f
if(typeof x!=="number")return x.i()
y.M(a,x,t,x+z,t)}y.ce(a)},
eQ:function(a,b){var z,y,x,w
z="end-"+H.b(b)
y=[U.ak]
x=H.o([],y)
y=H.o([],y)
w=$.$get$Q()
if(typeof w!=="number")return H.d(w)
w=new U.c8(null,null,null,z,null,null,0,0,0,0,null,null,0,null,x,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*w)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w.b8(a,z)
w.go=!1
z=$.$get$n()
if(typeof z!=="number")return z.aA()
w.x=z/2
this.x1=w
w.ry=this
this.ry.push(w)
this.rx=this.x1},
v:{
fn:function(a,b){var z,y,x,w
z=H.o([],[U.aC])
y=[U.ak]
x=H.o([],y)
y=H.o([],y)
w=$.$get$Q()
if(typeof w!=="number")return H.d(w)
w=new U.b9(z,null,null,null,b,null,null,0,0,0,0,null,null,0,null,x,y,"#6b9bc3","white","rgba(255, 255, 255, 0.6)","400 "+H.b(14*w)+"px 'Poppins', sans-serif",!1,a,!0,!1,null,null,null,null,!1,!0)
w.b8(a,b)
w.eQ(a,b)
return w}}},
c5:{"^":"e;",
aH:function(a,b,c){var z,y
for(z=this.a,y=0;y<b;++y)a.l+=z
a.l+=c+"\n"},
aG:function(a,b,c){var z,y,x,w,v,u,t,s,r,q
z=J.B(b)
y=z.h(b,"format")
x=z.h(b,"params")
w=z.h(b,"properties")
v=J.k(x)
u=!!v.$isf?v.gj(x):0
t=J.k(w)
s=!!t.$isf?t.gj(w):0
if(typeof y!=="string"){y=H.b(z.h(b,"action"))
for(r=0;r<u;++r)y+=" {"+r+"}"
for(r=0;r<s;++r)y+=" {P"+r+"}"}for(r=0;r<u;++r){z="{"+r+"}"
q=J.af(v.h(x,r),"value")
q=q==null?"":J.A(q)
if(typeof q!=="string")H.y(H.I(q))
y=H.f_(y,z,q)}for(r=0;r<s;++r){z="{P"+r+"}"
v=J.af(t.h(w,r),"value")
v=v==null?"":J.A(v)
if(typeof v!=="string")H.y(H.I(v))
y=H.f_(y,z,v)}this.aH(a,c,y)}},
hT:{"^":"c5;a",
d9:function(a){var z,y
z=new P.aG("")
for(y=J.L(a.h(0,"chains"));y.u();){this.ae(z,y.gw(),0)
z.l+="\n"}y=z.l
return y.charCodeAt(0)==0?y:y},
ae:function(a,b,c){var z,y,x,w,v,u
for(z=J.L(b),y=c+1;z.u();){x=z.gw()
this.aG(a,x,c)
w=J.B(x)
if(!!J.k(w.h(x,"children")).$isf)this.ae(a,w.h(x,"children"),y)
if(!!J.k(w.h(x,"clauses")).$isf)for(w=J.L(w.h(x,"clauses"));w.u();){v=w.gw()
this.aG(a,v,c)
u=J.B(v)
if(!!J.k(u.h(v,"children")).$isf)this.ae(a,u.h(v,"children"),y)}}}},
hH:{"^":"c5;a",
d9:function(a){var z,y,x,w
z=new P.aG("")
for(y=J.L(a.h(0,"chains"));y.u();){x=y.gw()
w=J.B(x)
if(J.bt(w.gj(x),0)&&J.N(J.af(w.h(x,0),"type"),"nlogo:procedure")){this.aG(z,w.ay(x,0),0)
this.ae(z,x,1)
w=z.l+="end\n"
z.l=w+"\n"}}y=z.l
return y.charCodeAt(0)==0?y:y},
ae:function(a,b,c){var z,y,x,w,v,u
for(z=J.L(b),y=c+1;z.u();){x=z.gw()
this.aG(a,x,c)
w=J.B(x)
if(!!J.k(w.h(x,"children")).$isf){this.aH(a,c,"[")
this.ae(a,w.h(x,"children"),y)
this.aH(a,c,"]")}if(!!J.k(w.h(x,"clauses")).$isf)for(w=J.L(w.h(x,"clauses"));w.u();){v=w.gw()
this.aG(a,v,c)
u=J.B(v)
if(!!J.k(u.h(v,"children")).$isf){this.aH(a,c,"[")
this.ae(a,u.h(v,"children"),y)
this.aH(a,c,"]")}}}}},
fp:{"^":"e;a,b,c,m:d>",
gq:function(a){return J.D(this.a.x,this.d)},
gt:function(a){return 0},
gp:function(a){return this.a.y},
br:function(a){return!1},
hN:function(a){var z
if(!a.gdg())if(!a.gdA()){z=J.m(a)
z=J.v(z.gq(a),J.l(z.gm(a),0.75))>=J.D(this.a.x,this.d)}else z=!1
else z=!1
return z},
bn:function(a){var z,y,x,w,v,u,t,s
z=$.$get$a5()
if(typeof z!=="number")return z.C()
this.d=z*1.5
for(z=this.b,y=z.length,x=0;x<z.length;z.length===y||(0,H.z)(z),++x){w=z[x]
v=this.d
u=w.a.da(a)
t=$.$get$M()
if(typeof t!=="number")return t.C()
if(typeof u!=="number")return u.i()
s=$.$get$bv()
if(typeof s!=="number")return s.C()
this.d=Math.max(v,u+t*2+s*2)}},
cg:function(a,b){var z,y,x,w,v,u,t,s
this.bn(a)
z=J.m(a)
z.S(a)
z.sak(a,this.c)
y=this.a
z.dK(a,J.D(y.x,this.d),0,this.d,y.y)
if(b)z.dK(a,J.D(y.x,this.d),0,this.d,y.y)
y=J.D(y.x,this.d)
x=$.$get$bv()
if(typeof x!=="number")return H.d(x)
w=y+x
x=$.$get$n()
if(typeof x!=="number")return x.aA()
v=0+x/2
for(y=this.b,u=y.length,t=0;t<y.length;y.length===u||(0,H.z)(y),++t){s=y[t]
s.b=w
s.c=v
s.hn(a)
v+=x*1.5}z.V(a)}},
dO:{"^":"e;a,q:b*,t:c*,d,e",
dT:function(){var z,y,x
z=this.e
y=J.ae(z)
x=y.G(z,this.d.bB(this.a.b))
return y.X(z,0)||J.bt(x,0)},
gm:function(a){return this.a.r},
gp:function(a){var z=this.a
return z.r1?$.$get$n():z.x},
hn:function(a){var z,y
z=this.a
J.D(this.e,this.d.bB(z.b))
y=J.m(a)
y.S(a)
if(!this.dT())y.seo(a,0.3)
z.e=this.b
z.f=this.c
z.c7(a,$.$get$a5())
z.bT(a)
z.bU(a)
z.bV(a)
y.V(a)},
bu:function(a){return this.a.bu(a)},
aa:function(a){var z,y,x,w,v
if(this.dT()){z=this.a
y=z.av(0)
x=z.e
if(typeof x!=="number")return x.G()
y.e=x-5
z=z.f
if(typeof z!=="number")return z.G()
y.f=z-5
y.r2=!0
z=this.d
z.bK(y)
if(!!y.$isb9)for(x=y.ry,w=x.length,v=0;v<x.length;x.length===w||(0,H.z)(x),++v)z.bK(x[v])
return y.aa(a)}return this},
b5:function(a){},
b3:function(a){},
b4:function(a){}},
ak:{"^":"e;a,b,c,d,e,f,r,x,y,m:z>,p:Q>,ch",
gF:function(a){var z=this.c
return z==null?"":J.A(z)},
sF:function(a,b){var z=b==null?"":J.A(b)
this.c=z
return z},
gb7:function(a){return H.b(J.A(this.c))+H.b(this.r)},
bt:function(a,b){return U.cp(b,this.W())},
W:["cO",function(){return P.at(["type",this.e,"name",this.f,"unit",this.r,"value",this.gF(this),"default",this.d])}],
bn:function(a){var z,y,x
z=$.$get$M()
if(typeof z!=="number")return z.C()
this.z=z*2
z=J.m(a)
z.S(a)
z.saw(a,this.b.fr)
y=this.z
x=z.cn(a,this.gb7(this)).width
if(typeof x!=="number")return H.d(x)
this.z=y+x
z.V(a)},
fJ:function(a){var z,y,x,w,v
this.bn(a)
z=this.z
y=J.m(a)
y.S(a)
y.saw(a,this.b.fr)
x=$.$get$ap()
w=y.cn(a,"\u25b8    "+H.b(this.f)).width
if(typeof x!=="number")return x.i()
if(typeof w!=="number")return H.d(w)
v=$.$get$M()
if(typeof v!=="number")return v.C()
y.V(a)
return z+(x+w+v*2)},
dJ:function(a,b,c){var z,y,x,w,v,u,t,s,r,q,p
this.x=b
this.y=c
z=this.b
y=J.m(a)
y.saw(a,z.fr)
y.scB(a,"center")
y.scC(a,"middle")
x=z.e
w=this.x
if(typeof x!=="number")return x.i()
v=x+w
w=z.f
x=this.y
if(typeof w!=="number")return w.i()
u=$.$get$n()
if(typeof u!=="number")return u.aA()
t=this.Q
s=t/2
r=w+x+u/2-s
q=this.z
y.at(a)
y.at(a)
u=v+s
y.aX(a,u,r)
x=v+q
w=x-s
y.A(a,w,r)
p=r+s
y.M(a,x,r,x,p)
t=r+t
s=t-s
y.A(a,x,s)
y.M(a,x,t,w,t)
y.A(a,u,t)
y.M(a,v,t,v,s)
y.A(a,v,p)
y.M(a,v,r,u,r)
y.ce(a)
y.sak(a,this.ch?z.db:z.dx)
y.cj(a)
y.sak(a,this.ch?z.dx:z.db)
y.ck(a,this.gb7(this),v+q/2,p)},
cg:function(a,b){return this.dJ(a,b,0)},
ho:function(a,b){var z,y,x,w,v,u,t,s,r
z=this.b
y=z.r
x=$.$get$M()
w=this.z
if(typeof x!=="number")return x.i()
if(typeof y!=="number")return y.G()
v=z.f
if(typeof v!=="number")return v.i()
u=$.$get$n()
if(typeof u!=="number")return u.aA()
t=z.e
s=$.$get$ap()
if(typeof t!=="number")return t.i()
if(typeof s!=="number")return H.d(s)
r=J.m(a)
r.sak(a,z.dx)
r.saw(a,z.fr)
r.scB(a,"left")
r.scC(a,"middle")
r.ck(a,"\u25b8    "+H.b(this.f),t+s,v+b+u/2)
this.dJ(a,y-(x+w),b)},
bu:function(a){var z,y,x,w,v
z=a.c
y=this.b
x=y.e
w=this.x
if(typeof x!=="number")return x.i()
w=x+w
if(z>=w){x=a.d
y=y.f
v=this.y
if(typeof y!=="number")return y.i()
v=y+v
if(x>=v)if(z<=w+this.z){z=$.$get$n()
if(typeof z!=="number")return H.d(z)
z=x<=v+z}else z=!1
else z=!1}else z=!1
return z},
b5:function(a){this.ch=!1
this.fS()
this.b.fy.a8()},
aa:function(a){this.ch=!0
this.b.fy.a8()
return this},
b3:function(a){},
b4:function(a){},
fS:function(){var z,y,x,w,v,u,t
z=document
y=z.createElement("div")
y.className="backdrop"
C.f.hH(y,"beforeend",'      <div class="nt-param-dialog">\n        <div class="nt-param-table">\n          <div class="nt-param-row">'+this.bb()+'</div>\n        </div>\n        <button class="nt-param-confirm">OK</button>\n        <button class="nt-param-cancel">Cancel</button>\n      </div>',null,null)
x=z.querySelector("#"+H.b(this.b.fy.f)).parentElement
if(x==null)return
x.appendChild(y)
w=z.querySelector("#nt-param-label-"+this.a)
v=z.querySelector("#nt-param-"+this.a)
u=[null]
t=[W.au]
new W.ef(new W.ei(z.querySelectorAll(".nt-param-confirm"),u),!1,"click",t).dV(new U.hP(this,y,v))
new W.ef(new W.ei(z.querySelectorAll(".nt-param-cancel"),u),!1,"click",t).dV(new U.hQ(y))
y.classList.add("show")
if(v!=null){z=J.m(v)
z.dL(v)
if(w!=null){u=z.gdZ(v)
W.aw(u.a,u.b,new U.hR(w,v),!1,H.H(u,0))
z=z.ge_(v)
W.aw(z.a,z.b,new U.hS(w,v),!1,H.H(z,0))}}},
bb:function(){return'      <input class="nt-param-input" id="nt-param-'+this.a+'" type="text" value="'+this.gb7(this)+'">\n      <span class="nt-param-unit">'+H.b(this.r)+"</span>\n    "},
aB:function(a,b){var z,y
z=$.dC
$.dC=z+1
this.a=z
z=J.B(b)
y=z.h(b,"type")
this.e=y==null?"number":J.A(y)
y=z.h(b,"name")
this.f=y==null?"":J.A(y)
y=z.h(b,"unit")
this.r=y==null?"":J.A(y)
z=z.h(b,"default")
this.d=z
this.sF(0,z)},
v:{
hO:function(a,b){var z=$.$get$n()
if(typeof z!=="number")return z.C()
z=new U.ak(null,a,null,null,"int","","",0,0,28,z*0.6,!1)
z.aB(a,b)
return z},
cp:function(a,b){var z,y
z=J.B(b)
y=z.h(b,"type")
switch(y==null?"number":J.A(y)){case"int":y=$.$get$n()
if(typeof y!=="number")return y.C()
y=new U.fW(!1,1,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.aB(a,b)
y.cx=U.bs(z.h(b,"random"),!1)
y.cy=U.an(z.h(b,"step"),y.cy)
y.cy=1
return y
case"num":case"number":y=$.$get$n()
if(typeof y!=="number")return y.C()
y=new U.co(!1,1,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.aB(a,b)
y.cx=U.bs(z.h(b,"random"),!1)
y.cy=U.an(z.h(b,"step"),y.cy)
return y
case"range":y=$.$get$n()
if(typeof y!=="number")return y.C()
y=new U.i5(0,10,!1,1,null,a,null,null,"int","","",0,0,28,y*0.6,!1)
y.aB(a,b)
y.cx=U.bs(z.h(b,"random"),!1)
y.cy=U.an(z.h(b,"step"),y.cy)
y.db=U.an(z.h(b,"min"),y.db)
y.dx=U.an(z.h(b,"max"),y.dx)
return y
case"select":return U.dN(a,b)
case"text":default:return U.hO(a,b)}}}},
hP:{"^":"h:0;a,b,c",
$1:[function(a){var z=this.c
if(z!=null)this.a.sF(0,J.c0(z))
C.f.ct(this.b)
z=this.a.b.fy
z.a8()
z.e5()},null,null,2,0,null,1,"call"]},
hQ:{"^":"h:0;a",
$1:[function(a){return C.f.ct(this.a)},null,null,2,0,null,1,"call"]},
hR:{"^":"h:0;a,b",
$1:function(a){J.cY(this.a,J.c0(this.b))}},
hS:{"^":"h:0;a,b",
$1:function(a){J.cY(this.a,J.c0(this.b))}},
co:{"^":"ak;cx,cy,a,b,c,d,e,f,r,x,y,z,Q,ch",
W:["eJ",function(){var z=this.cO()
z.n(0,"random",this.cx)
z.n(0,"step",this.cy)
return z}],
gF:function(a){return U.an(this.c,0)},
sF:function(a,b){var z=U.an(b,0)
this.c=z
return z},
gb7:function(a){var z=J.fl(H.kG(this.gF(this)),1)
if(C.d.hs(z,".0"))z=C.d.ac(z,0,z.length-2)
return z+H.b(this.r)},
bb:function(){return'      <div class="nt-param-name">'+H.b(this.f)+'</div>\n      <div class="nt-param-value">\n        <input class="nt-param-input" id="nt-param-'+this.a+'" type="number" step="'+H.b(this.cy)+'" value="'+H.b(this.gF(this))+'">\n        <span class="nt-param-unit">'+H.b(this.r)+"</span>\n      </div>\n    "}},
fW:{"^":"co;cx,cy,a,b,c,d,e,f,r,x,y,z,Q,ch",
gF:function(a){return U.cP(this.c,0)},
sF:function(a,b){var z=U.cP(b,0)
this.c=z
return z}},
i5:{"^":"co;db,dx,cx,cy,a,b,c,d,e,f,r,x,y,z,Q,ch",
W:function(){var z=this.eJ()
z.n(0,"min",this.db)
z.n(0,"max",this.dx)
return z},
bb:function(){return'      <div class="nt-param-name">'+H.b(this.f)+'</div>\n      <div class="nt-param-value">\n        <input class="nt-param-input" id="nt-param-'+this.a+'" type="range" value="'+H.b(U.an(this.c,0))+'" min="'+H.b(this.db)+'" max="'+H.b(this.dx)+'" step="'+H.b(this.cy)+'">\n      </div>\n      <div class="nt-param-label">\n        <label id="nt-param-label-'+this.a+'" for="nt-param-'+this.a+'">'+H.b(U.an(this.c,0))+'</label>\n        <span class="nt-param-unit">'+H.b(this.r)+"</span>\n      </div>\n    "}},
ia:{"^":"ak;cx,a,b,c,d,e,f,r,x,y,z,Q,ch",
gb7:function(a){return H.b(J.A(this.c))+H.b(this.r)+" \u25be"},
bt:function(a,b){return U.dN(b,this.W())},
W:function(){var z=this.cO()
z.n(0,"values",this.cx)
return z},
bb:function(){var z,y,x,w,v
z="<select id='nt-param-"+this.a+"'>"
for(y=J.L(this.cx);y.u();){x=y.gw()
w="<option value='"+H.b(x)+"' "
v=this.c
z+=w+(J.N(x,v==null?"":J.A(v))?"selected":"")+">"+H.b(x)+"</option>"}z+="</select>"
return'      <div class="nt-param-name">'+H.b(this.f)+'</div>\n      <div class="nt-param-value">'+z+"</div>\n    "},
eU:function(a,b){var z=J.B(b)
if(!!J.k(z.h(b,"values")).$isf&&J.bt(J.ag(z.h(b,"values")),0)){z=z.h(b,"values")
this.cx=z
this.c=J.af(z,0)}},
v:{
dN:function(a,b){var z=$.$get$n()
if(typeof z!=="number")return z.C()
z=new U.ia([],null,a,null,null,"int","","",0,0,28,z*0.6,!1)
z.aB(a,b)
z.eU(a,b)
return z}}},
d5:{"^":"dX;f,r,m:x>,p:y>,z,Q,ch,a,b,c,d,e",
ee:function(){if(this.br(0))this.a8()
C.K.gh3(window).ec(new U.fy(this))},
e5:function(){var z
this.a8()
try{J.af($.$get$cJ(),"NetTango").bs("_relayCallback",[this.f])}catch(z){H.C(z)
P.bW("Unable to relay program changed event to Javascript");P.bW(z);}},
ci:function(){var z,y,x,w,v,u,t,s
z=P.at(["chains",[]])
for(y=this.r,x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w){v=y[w]
if(v.gdU())J.aA(z.h(0,"chains"),v.ci())}for(y=this.z.b,x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w){u=y[w].a
if(u.fx)if(this.bB(u.b)===0){t=z.h(0,"chains")
s=[]
u.Z(s)
J.aA(t,s)}}return z},
bK:function(a){var z,y,x,w
this.r.push(a)
z=this.a
z.push(a)
for(y=a.ge3(),x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w)z.push(y[w])
for(y=a.ge6(),x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w)z.push(y[w])},
fG:function(a){var z,y,x,w
C.a.H(this.r,a)
z=this.a
C.a.H(z,a)
for(y=a.ge3(),x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w)C.a.H(z,y[w])
for(y=a.ge6(),x=y.length,w=0;w<y.length;y.length===x||(0,H.z)(y),++w)C.a.H(z,y[w])
this.a8()},
bB:function(a){var z,y,x,w
for(z=this.r,y=z.length,x=0,w=0;w<z.length;z.length===y||(0,H.z)(z),++w)if(J.N(J.f5(z[w]),a))++x
return x},
fT:function(a){var z,y,x
z=this.d8(a)
if(z!=null){y=z.gR()
z.sR(a)
a.z=z
if(y!=null){x=a.gaM()
y.sbz(x)
x.y=y}return!0}z=this.d7(a)
if(z!=null){z.sbz(a)
a.y=z
return!0}return!1},
fX:function(a){var z,y
if(this.z.hN(a))for(z=this.r,y=this.a;a!=null;){C.a.H(z,a)
C.a.H(y,a)
a=a.gbx()}},
d8:function(a){var z,y,x,w,v,u,t,s,r,q
if(a.gbz()==null&&a.gdP())for(z=this.r,y=z.length,x=J.m(a),w=0;w<z.length;z.length===y||(0,H.z)(z),++w){v=z[w]
u=J.k(v)
if(!u.B(v,a)){if(J.bY(x.gq(a),J.v(u.gq(v),u.gm(v)))){t=J.v(x.gq(a),x.gm(a))
s=u.gq(v)
if(typeof s!=="number")return H.d(s)
s=t>s
t=s}else t=!1
if(t){r=u.gt(v)
q=J.v(u.gt(v),u.gp(v))
u=J.l(u.gp(v),0.8)
if(typeof u!=="number")return H.d(u)
if(v.gaQ()){t=a.gb2()
if(typeof t!=="number")return t.X()
if(t<q){t=a.gb2()
if(typeof t!=="number")return t.an()
if(typeof r!=="number")return H.d(r)
t=t>r}else t=!1}else t=!1
if(t)return v
else{if(!v.gaQ()){t=a.gb2()
if(typeof t!=="number")return t.an()
if(typeof r!=="number")return H.d(r)
if(t>r){t=a.gb2()
if(typeof t!=="number")return t.X()
u=t<q+u}else u=!1}else u=!1
if(u)return v}}}}return},
d7:function(a){var z,y,x,w,v,u,t
if(a.gR()==null)for(z=this.r,y=z.length,x=J.m(a),w=0;w<z.length;z.length===y||(0,H.z)(z),++w){v=z[w]
u=J.k(v)
if(!u.B(v,a)&&v.gbz()==null&&v.gdP()){if(J.bY(x.gq(a),J.v(u.gq(v),u.gm(v)))){t=J.v(x.gq(a),x.gm(a))
u=u.gq(v)
if(typeof u!=="number")return H.d(u)
u=t>u}else u=!1
if(u){u=v.gb2()
t=a.gh7()
if(typeof u!=="number")return u.G()
if(Math.abs(u-t)<20)return v}}}return},
br:function(a){var z,y,x,w
this.z.toString
for(z=this.r,y=z.length,x=!1,w=0;w<z.length;z.length===y||(0,H.z)(z),++w)if(J.f3(z[w]))x=!0
return x},
a8:function(){var z,y,x,w,v,u,t,s,r
J.fg(this.Q)
J.f4(this.Q,0,0,this.x,this.y)
z=H.o([],[U.ba])
for(y=this.r,x=y.length,w=!1,v=0;v<y.length;y.length===x||(0,H.z)(y),++v){u=y[v]
if(!u.ghF()&&!(u instanceof U.aC)){u.a4(0,null)
u.bm()
u.c7(this.Q,$.$get$a5())}if(u.gd5())z.push(u)
t=this.z
t.toString
if(!u.gdg())if(!u.gdA()){s=J.m(u)
t=J.v(s.gq(u),J.l(s.gm(u),0.75))>=J.D(t.a.x,t.d)}else t=!1
else t=!1
if(t)w=!0}this.z.cg(this.Q,w)
for(x=y.length,v=0;v<y.length;y.length===x||(0,H.z)(y),++v){u=y[v]
if(u.gd5()){r=this.d8(u)
if(r!=null)r.fa(this.Q)
else{r=this.d7(u)
if(r!=null)r.fd(this.Q)}}u.bT(this.Q)
u.bU(this.Q)
u.fb(this.Q)
u.fc(this.Q)
u.bV(this.Q)}J.ff(this.Q)},
eR:function(a,b){var z,y,x,w,v,u,t,s
z=this.f
y="#"+H.b(z)
x=document.querySelector(y)
if(x==null)throw H.c("No canvas element with ID "+H.b(z)+" found.")
z=J.m(x)
this.Q=z.em(x,"2d")
y=x.style
w=H.b(z.gm(x))+"px"
y.width=w
y=x.style
w=H.b(z.gp(x))+"px"
y.height=w
y=z.gm(x)
w=$.$get$Q()
this.x=J.l(y,w)
this.y=J.l(z.gp(x),w)
z.sm(x,this.x)
z.sp(x,this.y)
if(typeof w!=="number")return H.d(w)
z=this.c
y=new U.bE([1,0,0,0,1,0,0,0,1])
y.a=[1/w,0,0,0,1/w,0,0,0,1]
z.hU(y)
this.d=this.c.hL()
y=this.ch
y.i_(x)
y.c.push(this)
y=H.o([],[U.dO])
z=$.$get$a5()
w=$.$get$bv()
if(typeof w!=="number")return w.C()
if(typeof z!=="number")return z.i()
this.z=new U.fp(this,y,"rgba(0,0,0, 0.2)",z+w*2)
if(!!J.k(b.h(0,"blocks")).$isf)for(z=J.L(b.h(0,"blocks"));z.u();){v=z.gw()
u=U.d0(this,v)
t=U.cP(J.af(v,"limit"),-1)
y=this.z
w=y.b
y=y.a
s=new U.dO(u,null,null,y,t)
u.r1=!0
y.a.push(s)
w.push(s)}this.a8()
this.ee()},
v:{
fx:function(a,b){var z,y,x,w,v
z=H.o([],[U.ba])
y=H.o([],[U.dX])
x=P.r
w=U.ix
v=H.o([],[w])
z=new U.d5(a,z,null,null,null,null,new U.ir(!1,null,y,new H.U(0,null,null,null,null,null,0,[x,U.dW])),v,new H.U(0,null,null,null,null,null,0,[x,w]),new U.bE([1,0,0,0,1,0,0,0,1]),new U.bE([1,0,0,0,1,0,0,0,1]),new P.aT(Date.now(),!1))
z.eR(a,b)
return z}}},
fy:{"^":"h:0;a",
$1:function(a){return this.a.ee()}},
bE:{"^":"e;a",
hL:function(){var z,y,x,w,v,u,t,s,r,q,p,o
z=[1,0,0,0,1,0,0,0,1]
y=new U.bE(z)
x=this.a
w=x.length
if(0>=w)return H.a(x,0)
v=x[0]
if(4>=w)return H.a(x,4)
u=x[4]
if(8>=w)return H.a(x,8)
u=J.l(u,x[8])
w=this.a
if(7>=w.length)return H.a(w,7)
t=J.l(v,J.D(u,J.l(w[7],w[5])))
w=this.a
u=w.length
if(3>=u)return H.a(w,3)
v=w[3]
s=w[1]
if(8>=u)return H.a(w,8)
w=J.l(s,w[8])
s=this.a
if(7>=s.length)return H.a(s,7)
r=J.l(v,J.D(w,J.l(s[7],s[2])))
s=this.a
if(6>=s.length)return H.a(s,6)
w=s[6]
s=J.l(s[1],s[5])
v=this.a
if(4>=v.length)return H.a(v,4)
q=J.l(w,J.D(s,J.l(v[4],v[2])))
p=J.v(J.D(t,r),q)
if(J.N(p,0))return y
if(typeof p!=="number")return H.d(p)
o=1/p
w=x.length
if(4>=w)return H.a(x,4)
v=x[4]
if(8>=w)return H.a(x,8)
v=J.l(v,x[8])
if(7>=x.length)return H.a(x,7)
v=J.D(v,J.l(x[7],x[5]))
if(typeof v!=="number")return H.d(v)
if(0>=z.length)return H.a(z,0)
z[0]=o*v
if(6>=x.length)return H.a(x,6)
v=J.l(x[6],x[5])
w=x.length
if(3>=w)return H.a(x,3)
u=x[3]
if(8>=w)return H.a(x,8)
u=J.D(v,J.l(u,x[8]))
if(typeof u!=="number")return H.d(u)
if(3>=z.length)return H.a(z,3)
z[3]=o*u
u=x.length
if(3>=u)return H.a(x,3)
v=x[3]
if(7>=u)return H.a(x,7)
v=J.l(v,x[7])
if(6>=x.length)return H.a(x,6)
v=J.D(v,J.l(x[6],x[4]))
if(typeof v!=="number")return H.d(v)
if(6>=z.length)return H.a(z,6)
z[6]=o*v
if(7>=x.length)return H.a(x,7)
v=J.l(x[7],x[2])
u=x.length
if(1>=u)return H.a(x,1)
w=x[1]
if(8>=u)return H.a(x,8)
w=J.D(v,J.l(w,x[8]))
if(typeof w!=="number")return H.d(w)
if(1>=z.length)return H.a(z,1)
z[1]=o*w
w=x.length
if(0>=w)return H.a(x,0)
v=x[0]
if(8>=w)return H.a(x,8)
v=J.l(v,x[8])
if(6>=x.length)return H.a(x,6)
v=J.D(v,J.l(x[6],x[2]))
if(typeof v!=="number")return H.d(v)
if(4>=z.length)return H.a(z,4)
z[4]=o*v
if(6>=x.length)return H.a(x,6)
v=J.l(x[6],x[1])
w=x.length
if(0>=w)return H.a(x,0)
u=x[0]
if(7>=w)return H.a(x,7)
u=J.D(v,J.l(u,x[7]))
if(typeof u!=="number")return H.d(u)
if(7>=z.length)return H.a(z,7)
z[7]=o*u
u=x.length
if(1>=u)return H.a(x,1)
v=x[1]
if(5>=u)return H.a(x,5)
v=J.l(v,x[5])
if(4>=x.length)return H.a(x,4)
v=J.D(v,J.l(x[4],x[2]))
if(typeof v!=="number")return H.d(v)
if(2>=z.length)return H.a(z,2)
z[2]=o*v
if(3>=x.length)return H.a(x,3)
v=J.l(x[3],x[2])
u=x.length
if(0>=u)return H.a(x,0)
w=x[0]
if(5>=u)return H.a(x,5)
w=J.D(v,J.l(w,x[5]))
if(typeof w!=="number")return H.d(w)
if(5>=z.length)return H.a(z,5)
z[5]=o*w
w=x.length
if(0>=w)return H.a(x,0)
v=x[0]
if(4>=w)return H.a(x,4)
v=J.l(v,x[4])
if(3>=x.length)return H.a(x,3)
v=J.D(v,J.l(x[3],x[1]))
if(typeof v!=="number")return H.d(v)
if(8>=z.length)return H.a(z,8)
z[8]=o*v
return y},
hU:function(a){var z,y,x,w,v,u
z=[1,0,0,0,1,0,0,0,1]
y=this.a
if(0>=y.length)return H.a(y,0)
y=y[0]
x=a.a
if(0>=x.length)return H.a(x,0)
x=J.l(y,x[0])
y=this.a
if(1>=y.length)return H.a(y,1)
y=y[1]
w=a.a
if(3>=w.length)return H.a(w,3)
w=J.v(x,J.l(y,w[3]))
y=this.a
if(2>=y.length)return H.a(y,2)
y=y[2]
x=a.a
if(6>=x.length)return H.a(x,6)
x=J.v(w,J.l(y,x[6]))
if(0>=z.length)return H.a(z,0)
z[0]=x
x=this.a
if(0>=x.length)return H.a(x,0)
x=x[0]
y=a.a
if(1>=y.length)return H.a(y,1)
y=J.l(x,y[1])
x=this.a
if(1>=x.length)return H.a(x,1)
x=x[1]
w=a.a
if(4>=w.length)return H.a(w,4)
w=J.v(y,J.l(x,w[4]))
x=this.a
if(2>=x.length)return H.a(x,2)
x=x[2]
y=a.a
if(7>=y.length)return H.a(y,7)
y=J.v(w,J.l(x,y[7]))
if(1>=z.length)return H.a(z,1)
z[1]=y
y=this.a
if(0>=y.length)return H.a(y,0)
y=y[0]
x=a.a
if(2>=x.length)return H.a(x,2)
x=J.l(y,x[2])
y=this.a
if(1>=y.length)return H.a(y,1)
y=y[1]
w=a.a
if(5>=w.length)return H.a(w,5)
w=J.v(x,J.l(y,w[5]))
y=this.a
if(2>=y.length)return H.a(y,2)
y=y[2]
x=a.a
if(8>=x.length)return H.a(x,8)
x=J.v(w,J.l(y,x[8]))
if(2>=z.length)return H.a(z,2)
z[2]=x
x=this.a
if(3>=x.length)return H.a(x,3)
x=x[3]
y=a.a
if(0>=y.length)return H.a(y,0)
y=J.l(x,y[0])
x=this.a
if(4>=x.length)return H.a(x,4)
x=x[4]
w=a.a
if(3>=w.length)return H.a(w,3)
w=J.v(y,J.l(x,w[3]))
x=this.a
if(5>=x.length)return H.a(x,5)
x=x[5]
y=a.a
if(6>=y.length)return H.a(y,6)
y=J.v(w,J.l(x,y[6]))
if(3>=z.length)return H.a(z,3)
z[3]=y
y=this.a
if(3>=y.length)return H.a(y,3)
y=y[3]
x=a.a
if(1>=x.length)return H.a(x,1)
x=J.l(y,x[1])
y=this.a
if(4>=y.length)return H.a(y,4)
y=y[4]
w=a.a
if(4>=w.length)return H.a(w,4)
w=J.v(x,J.l(y,w[4]))
y=this.a
if(5>=y.length)return H.a(y,5)
y=y[5]
x=a.a
if(7>=x.length)return H.a(x,7)
x=J.v(w,J.l(y,x[7]))
if(4>=z.length)return H.a(z,4)
z[4]=x
x=this.a
if(3>=x.length)return H.a(x,3)
x=x[3]
y=a.a
if(2>=y.length)return H.a(y,2)
y=J.l(x,y[2])
x=this.a
if(4>=x.length)return H.a(x,4)
x=x[4]
w=a.a
if(5>=w.length)return H.a(w,5)
w=J.v(y,J.l(x,w[5]))
x=this.a
if(5>=x.length)return H.a(x,5)
x=x[5]
y=a.a
if(8>=y.length)return H.a(y,8)
y=J.v(w,J.l(x,y[8]))
if(5>=z.length)return H.a(z,5)
z[5]=y
y=this.a
if(6>=y.length)return H.a(y,6)
y=y[6]
x=a.a
if(0>=x.length)return H.a(x,0)
x=J.l(y,x[0])
y=this.a
if(7>=y.length)return H.a(y,7)
y=y[7]
w=a.a
if(3>=w.length)return H.a(w,3)
w=J.v(x,J.l(y,w[3]))
y=this.a
if(8>=y.length)return H.a(y,8)
y=y[8]
x=a.a
if(6>=x.length)return H.a(x,6)
x=J.v(w,J.l(y,x[6]))
if(6>=z.length)return H.a(z,6)
z[6]=x
x=this.a
if(6>=x.length)return H.a(x,6)
x=x[6]
y=a.a
if(1>=y.length)return H.a(y,1)
y=J.l(x,y[1])
x=this.a
if(7>=x.length)return H.a(x,7)
x=x[7]
w=a.a
if(4>=w.length)return H.a(w,4)
w=J.v(y,J.l(x,w[4]))
x=this.a
if(8>=x.length)return H.a(x,8)
x=x[8]
y=a.a
if(7>=y.length)return H.a(y,7)
y=J.v(w,J.l(x,y[7]))
if(7>=z.length)return H.a(z,7)
z[7]=y
y=this.a
if(6>=y.length)return H.a(y,6)
y=y[6]
x=a.a
if(2>=x.length)return H.a(x,2)
x=J.l(y,x[2])
y=this.a
if(7>=y.length)return H.a(y,7)
y=y[7]
w=a.a
if(5>=w.length)return H.a(w,5)
w=J.v(x,J.l(y,w[5]))
y=this.a
if(8>=y.length)return H.a(y,8)
y=y[8]
x=a.a
if(8>=x.length)return H.a(x,8)
x=J.v(w,J.l(y,x[8]))
y=z.length
if(8>=y)return H.a(z,8)
z[8]=x
for(x=this.a,w=x.length,v=0;v<9;++v){if(v>=y)return H.a(z,v)
u=z[v]
if(v>=w)return H.a(x,v)
x[v]=u}},
az:function(a){var z,y,x,w,v,u,t,s,r
z=a.c
y=this.a
x=y.length
if(0>=x)return H.a(y,0)
w=y[0]
if(typeof w!=="number")return H.d(w)
v=a.d
if(1>=x)return H.a(y,1)
u=y[1]
if(typeof u!=="number")return H.d(u)
if(2>=x)return H.a(y,2)
t=y[2]
if(typeof t!=="number")return H.d(t)
if(3>=x)return H.a(y,3)
s=y[3]
if(typeof s!=="number")return H.d(s)
if(4>=x)return H.a(y,4)
r=y[4]
if(typeof r!=="number")return H.d(r)
if(5>=x)return H.a(y,5)
y=y[5]
if(typeof y!=="number")return H.d(y)
a.c=z*w+v*u+t
a.d=z*s+v*r+y}},
ir:{"^":"e;a,b,c,d",
bv:function(a){var z,y,x
for(z=this.c,y=0;y<z.length;++y){x=z[y].bv(a)
if(x!=null){if(y>=z.length)return H.a(z,y)
z[y].e=new P.aT(Date.now(),!1)
if(y>=z.length)return H.a(z,y)
return new U.dW(z[y],x)}else if(y>=z.length)return H.a(z,y)}return},
i_:function(a){var z,y
this.b=a
z=J.m(a)
y=z.ge0(a)
W.aw(y.a,y.b,new U.is(this),!1,H.H(y,0))
y=z.ge2(a)
W.aw(y.a,y.b,new U.it(this),!1,H.H(y,0))
z=z.ge1(a)
W.aw(z.a,z.b,new U.iu(this),!1,H.H(z,0))
z=document
W.aw(z,"keydown",new U.iv(this),!1,W.ly)
W.aw(z,"touchmove",new U.iw(),!1,W.mk)},
fs:function(a){var z,y
for(z=this.c.length,y=0;y<z;++y);}},
is:{"^":"h:0;a",
$1:function(a){var z,y,x
z=this.a
y=U.c6(a)
x=z.bv(y)
if(x!=null)if(x.aa(y))z.d.n(0,-1,x)
z.a=!0
return}},
it:{"^":"h:0;a",
$1:function(a){var z,y,x
z=this.a
y=z.d
x=y.h(0,-1)
if(x!=null)x.b5(U.c6(a))
y.n(0,-1,null)
z.a=!1
return}},
iu:{"^":"h:0;a",
$1:function(a){var z,y,x
z=this.a
y=U.c6(a)
x=z.d.h(0,-1)
if(x!=null)x.b3(y)
else{x=z.bv(y)
if(x!=null)if(z.a){x.a.d.az(y)
x.b.b4(y)}}return}},
iv:{"^":"h:0;a",
$1:function(a){return this.a.fs(a)}},
iw:{"^":"h:0;",
$1:function(a){return J.fc(a)}},
dX:{"^":"e;",
bv:function(a){var z,y,x
z=new U.d6(null,-1,0,0,!1,!1,!1,!1,!1)
z.a=a.a
z.b=a.b
z.c=a.c
z.d=a.d
z.y=a.y
this.d.az(z)
for(y=this.a,x=y.length-1;x>=0;--x){if(x>=y.length)return H.a(y,x)
if(y[x].bu(z)){if(x>=y.length)return H.a(y,x)
return y[x]}}return}},
dW:{"^":"e;a,b",
aa:function(a){this.a.d.az(a)
this.b=this.b.aa(a)
return!0},
b5:function(a){this.a.d.az(a)
this.b.b5(a)},
b3:function(a){this.a.d.az(a)
this.b.b3(a)},
b4:function(a){this.a.d.az(a)
this.b.b4(a)}},
ix:{"^":"e;"},
d6:{"^":"e;a,b,c,d,e,f,r,x,y",
eS:function(a){var z,y
this.a=-1
z=J.m(a)
y=z.gby(a)
y=y.gq(y)
y.toString
this.c=y
z=z.gby(a)
z=z.gt(z)
z.toString
this.d=z
this.y=!0},
v:{
c6:function(a){var z=new U.d6(null,-1,0,0,!1,!1,!1,!1,!1)
z.eS(a)
return z}}}},1]]
setupProgram(dart,0)
J.k=function(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.dp.prototype
return J.hh.prototype}if(typeof a=="string")return J.bh.prototype
if(a==null)return J.hj.prototype
if(typeof a=="boolean")return J.hg.prototype
if(a.constructor==Array)return J.bf.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bi.prototype
return a}if(a instanceof P.e)return a
return J.bS(a)}
J.B=function(a){if(typeof a=="string")return J.bh.prototype
if(a==null)return a
if(a.constructor==Array)return J.bf.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bi.prototype
return a}if(a instanceof P.e)return a
return J.bS(a)}
J.b5=function(a){if(a==null)return a
if(a.constructor==Array)return J.bf.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bi.prototype
return a}if(a instanceof P.e)return a
return J.bS(a)}
J.ae=function(a){if(typeof a=="number")return J.bg.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bn.prototype
return a}
J.eO=function(a){if(typeof a=="number")return J.bg.prototype
if(typeof a=="string")return J.bh.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bn.prototype
return a}
J.eP=function(a){if(typeof a=="string")return J.bh.prototype
if(a==null)return a
if(!(a instanceof P.e))return J.bn.prototype
return a}
J.m=function(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.bi.prototype
return a}if(a instanceof P.e)return a
return J.bS(a)}
J.v=function(a,b){if(typeof a=="number"&&typeof b=="number")return a+b
return J.eO(a).i(a,b)}
J.N=function(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.k(a).B(a,b)}
J.bt=function(a,b){if(typeof a=="number"&&typeof b=="number")return a>b
return J.ae(a).an(a,b)}
J.bY=function(a,b){if(typeof a=="number"&&typeof b=="number")return a<b
return J.ae(a).X(a,b)}
J.l=function(a,b){if(typeof a=="number"&&typeof b=="number")return a*b
return J.eO(a).C(a,b)}
J.cQ=function(a,b){return J.ae(a).ey(a,b)}
J.D=function(a,b){if(typeof a=="number"&&typeof b=="number")return a-b
return J.ae(a).G(a,b)}
J.f1=function(a,b){if(typeof a=="number"&&typeof b=="number")return(a^b)>>>0
return J.ae(a).eP(a,b)}
J.af=function(a,b){if(typeof b==="number")if(a.constructor==Array||typeof a=="string"||H.eT(a,a[init.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.B(a).h(a,b)}
J.bZ=function(a,b,c){if(typeof b==="number")if((a.constructor==Array||H.eT(a,a[init.dispatchPropertyName]))&&!a.immutable$list&&b>>>0===b&&b<a.length)return a[b]=c
return J.b5(a).n(a,b,c)}
J.aA=function(a,b){return J.b5(a).D(a,b)}
J.f2=function(a,b,c,d){return J.m(a).dB(a,b,c,d)}
J.f3=function(a){return J.m(a).br(a)}
J.f4=function(a,b,c,d,e){return J.m(a).h8(a,b,c,d,e)}
J.cR=function(a,b){return J.m(a).bt(a,b)}
J.c_=function(a,b,c){return J.B(a).ha(a,b,c)}
J.cS=function(a,b){return J.b5(a).O(a,b)}
J.f5=function(a){return J.m(a).gcb(a)}
J.cT=function(a){return J.m(a).gh4(a)}
J.b7=function(a){return J.m(a).gaj(a)}
J.T=function(a){return J.k(a).gE(a)}
J.L=function(a){return J.b5(a).gK(a)}
J.ag=function(a){return J.B(a).gj(a)}
J.f6=function(a){return J.m(a).ghW(a)}
J.f7=function(a){return J.m(a).ghY(a)}
J.cU=function(a){return J.m(a).gI(a)}
J.f8=function(a){return J.m(a).gcF(a)}
J.c0=function(a){return J.m(a).gF(a)}
J.cV=function(a){return J.m(a).gm(a)}
J.b8=function(a){return J.m(a).gt(a)}
J.f9=function(a){return J.m(a).cI(a)}
J.cW=function(a,b,c){return J.m(a).A(a,b,c)}
J.cX=function(a,b){return J.b5(a).am(a,b)}
J.fa=function(a,b,c){return J.eP(a).hR(a,b,c)}
J.fb=function(a,b){return J.k(a).cp(a,b)}
J.fc=function(a){return J.m(a).hX(a)}
J.fd=function(a){return J.b5(a).ct(a)}
J.fe=function(a,b,c,d){return J.m(a).e7(a,b,c,d)}
J.ff=function(a){return J.m(a).V(a)}
J.fg=function(a){return J.m(a).S(a)}
J.aQ=function(a,b){return J.m(a).bD(a,b)}
J.fh=function(a,b){return J.m(a).sbw(a,b)}
J.cY=function(a,b){return J.m(a).sdS(a,b)}
J.fi=function(a,b){return J.m(a).sq(a,b)}
J.fj=function(a,b){return J.m(a).st(a,b)}
J.cZ=function(a){return J.ae(a).cD(a)}
J.fk=function(a){return J.eP(a).i5(a)}
J.A=function(a){return J.k(a).k(a)}
J.fl=function(a,b){return J.ae(a).i6(a,b)}
I.az=function(a){a.immutable$list=Array
a.fixed$length=Array
return a}
var $=I.p
C.l=W.c2.prototype
C.f=W.fL.prototype
C.w=J.i.prototype
C.a=J.bf.prototype
C.c=J.dp.prototype
C.e=J.bg.prototype
C.d=J.bh.prototype
C.D=J.bi.prototype
C.r=J.hU.prototype
C.t=W.ik.prototype
C.k=J.bn.prototype
C.K=W.bL.prototype
C.u=new P.hN()
C.v=new P.iT()
C.b=new P.jx()
C.m=new P.aD(0)
C.x=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
C.y=function(hooks) {
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
C.n=function(hooks) { return hooks; }

C.z=function(getTagFallback) {
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
C.A=function() {
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
C.B=function(hooks) {
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
C.C=function(hooks) {
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
C.o=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
C.p=new P.ht(null,null)
C.E=new P.hv(null)
C.F=new P.hw(null,null)
C.G=H.o(I.az(["*::class","*::dir","*::draggable","*::hidden","*::id","*::inert","*::itemprop","*::itemref","*::itemscope","*::lang","*::spellcheck","*::title","*::translate","A::accesskey","A::coords","A::hreflang","A::name","A::shape","A::tabindex","A::target","A::type","AREA::accesskey","AREA::alt","AREA::coords","AREA::nohref","AREA::shape","AREA::tabindex","AREA::target","AUDIO::controls","AUDIO::loop","AUDIO::mediagroup","AUDIO::muted","AUDIO::preload","BDO::dir","BODY::alink","BODY::bgcolor","BODY::link","BODY::text","BODY::vlink","BR::clear","BUTTON::accesskey","BUTTON::disabled","BUTTON::name","BUTTON::tabindex","BUTTON::type","BUTTON::value","CANVAS::height","CANVAS::width","CAPTION::align","COL::align","COL::char","COL::charoff","COL::span","COL::valign","COL::width","COLGROUP::align","COLGROUP::char","COLGROUP::charoff","COLGROUP::span","COLGROUP::valign","COLGROUP::width","COMMAND::checked","COMMAND::command","COMMAND::disabled","COMMAND::label","COMMAND::radiogroup","COMMAND::type","DATA::value","DEL::datetime","DETAILS::open","DIR::compact","DIV::align","DL::compact","FIELDSET::disabled","FONT::color","FONT::face","FONT::size","FORM::accept","FORM::autocomplete","FORM::enctype","FORM::method","FORM::name","FORM::novalidate","FORM::target","FRAME::name","H1::align","H2::align","H3::align","H4::align","H5::align","H6::align","HR::align","HR::noshade","HR::size","HR::width","HTML::version","IFRAME::align","IFRAME::frameborder","IFRAME::height","IFRAME::marginheight","IFRAME::marginwidth","IFRAME::width","IMG::align","IMG::alt","IMG::border","IMG::height","IMG::hspace","IMG::ismap","IMG::name","IMG::usemap","IMG::vspace","IMG::width","INPUT::accept","INPUT::accesskey","INPUT::align","INPUT::alt","INPUT::autocomplete","INPUT::autofocus","INPUT::checked","INPUT::disabled","INPUT::inputmode","INPUT::ismap","INPUT::list","INPUT::max","INPUT::maxlength","INPUT::min","INPUT::multiple","INPUT::name","INPUT::placeholder","INPUT::readonly","INPUT::required","INPUT::size","INPUT::step","INPUT::tabindex","INPUT::type","INPUT::usemap","INPUT::value","INS::datetime","KEYGEN::disabled","KEYGEN::keytype","KEYGEN::name","LABEL::accesskey","LABEL::for","LEGEND::accesskey","LEGEND::align","LI::type","LI::value","LINK::sizes","MAP::name","MENU::compact","MENU::label","MENU::type","METER::high","METER::low","METER::max","METER::min","METER::value","OBJECT::typemustmatch","OL::compact","OL::reversed","OL::start","OL::type","OPTGROUP::disabled","OPTGROUP::label","OPTION::disabled","OPTION::label","OPTION::selected","OPTION::value","OUTPUT::for","OUTPUT::name","P::align","PRE::width","PROGRESS::max","PROGRESS::min","PROGRESS::value","SELECT::autocomplete","SELECT::disabled","SELECT::multiple","SELECT::name","SELECT::required","SELECT::size","SELECT::tabindex","SOURCE::type","TABLE::align","TABLE::bgcolor","TABLE::border","TABLE::cellpadding","TABLE::cellspacing","TABLE::frame","TABLE::rules","TABLE::summary","TABLE::width","TBODY::align","TBODY::char","TBODY::charoff","TBODY::valign","TD::abbr","TD::align","TD::axis","TD::bgcolor","TD::char","TD::charoff","TD::colspan","TD::headers","TD::height","TD::nowrap","TD::rowspan","TD::scope","TD::valign","TD::width","TEXTAREA::accesskey","TEXTAREA::autocomplete","TEXTAREA::cols","TEXTAREA::disabled","TEXTAREA::inputmode","TEXTAREA::name","TEXTAREA::placeholder","TEXTAREA::readonly","TEXTAREA::required","TEXTAREA::rows","TEXTAREA::tabindex","TEXTAREA::wrap","TFOOT::align","TFOOT::char","TFOOT::charoff","TFOOT::valign","TH::abbr","TH::align","TH::axis","TH::bgcolor","TH::char","TH::charoff","TH::colspan","TH::headers","TH::height","TH::nowrap","TH::rowspan","TH::scope","TH::valign","TH::width","THEAD::align","THEAD::char","THEAD::charoff","THEAD::valign","TR::align","TR::bgcolor","TR::char","TR::charoff","TR::valign","TRACK::default","TRACK::kind","TRACK::label","TRACK::srclang","UL::compact","UL::type","VIDEO::controls","VIDEO::height","VIDEO::loop","VIDEO::mediagroup","VIDEO::muted","VIDEO::preload","VIDEO::width"]),[P.p])
C.H=I.az(["HEAD","AREA","BASE","BASEFONT","BR","COL","COLGROUP","EMBED","FRAME","FRAMESET","HR","IMAGE","IMG","INPUT","ISINDEX","LINK","META","PARAM","SOURCE","STYLE","TITLE","WBR"])
C.h=I.az([])
C.i=H.o(I.az(["bind","if","ref","repeat","syntax"]),[P.p])
C.j=H.o(I.az(["A::href","AREA::href","BLOCKQUOTE::cite","BODY::background","COMMAND::icon","DEL::cite","FORM::action","IMG::src","INPUT::src","INS::cite","Q::cite","VIDEO::poster"]),[P.p])
C.I=H.o(I.az([]),[P.bm])
C.q=new H.fD(0,{},C.I,[P.bm,null])
C.J=new H.ct("call")
$.dG="$cachedFunction"
$.dH="$cachedInvocation"
$.a7=0
$.aS=null
$.d1=null
$.cL=null
$.eI=null
$.eX=null
$.bR=null
$.bU=null
$.cM=null
$.aJ=null
$.b1=null
$.b2=null
$.cF=!1
$.q=C.b
$.dh=0
$.ai=null
$.c7=null
$.dg=null
$.df=null
$.dc=null
$.db=null
$.da=null
$.d9=null
$.a6=0
$.bb=null
$.dC=0
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
I.$lazy(y,x,w)}})(["bx","$get$bx",function(){return H.cK("_$dart_dartClosure")},"cd","$get$cd",function(){return H.cK("_$dart_js")},"dk","$get$dk",function(){return H.hc()},"dl","$get$dl",function(){if(typeof WeakMap=="function")var z=new WeakMap()
else{z=$.dh
$.dh=z+1
z="expando$key$"+z}return new P.fS(null,z)},"dY","$get$dY",function(){return H.aa(H.bK({
toString:function(){return"$receiver$"}}))},"dZ","$get$dZ",function(){return H.aa(H.bK({$method$:null,
toString:function(){return"$receiver$"}}))},"e_","$get$e_",function(){return H.aa(H.bK(null))},"e0","$get$e0",function(){return H.aa(function(){var $argumentsExpr$='$arguments$'
try{null.$method$($argumentsExpr$)}catch(z){return z.message}}())},"e4","$get$e4",function(){return H.aa(H.bK(void 0))},"e5","$get$e5",function(){return H.aa(function(){var $argumentsExpr$='$arguments$'
try{(void 0).$method$($argumentsExpr$)}catch(z){return z.message}}())},"e2","$get$e2",function(){return H.aa(H.e3(null))},"e1","$get$e1",function(){return H.aa(function(){try{null.$method$}catch(z){return z.message}}())},"e7","$get$e7",function(){return H.aa(H.e3(void 0))},"e6","$get$e6",function(){return H.aa(function(){try{(void 0).$method$}catch(z){return z.message}}())},"cv","$get$cv",function(){return P.iE()},"be","$get$be",function(){var z,y
z=P.aX
y=new P.ac(0,P.iD(),null,[z])
y.eZ(null,z)
return y},"b3","$get$b3",function(){return[]},"em","$get$em",function(){return P.dr(["A","ABBR","ACRONYM","ADDRESS","AREA","ARTICLE","ASIDE","AUDIO","B","BDI","BDO","BIG","BLOCKQUOTE","BR","BUTTON","CANVAS","CAPTION","CENTER","CITE","CODE","COL","COLGROUP","COMMAND","DATA","DATALIST","DD","DEL","DETAILS","DFN","DIR","DIV","DL","DT","EM","FIELDSET","FIGCAPTION","FIGURE","FONT","FOOTER","FORM","H1","H2","H3","H4","H5","H6","HEADER","HGROUP","HR","I","IFRAME","IMG","INPUT","INS","KBD","LABEL","LEGEND","LI","MAP","MARK","MENU","METER","NAV","NOBR","OL","OPTGROUP","OPTION","OUTPUT","P","PRE","PROGRESS","Q","S","SAMP","SECTION","SELECT","SMALL","SOURCE","SPAN","STRIKE","STRONG","SUB","SUMMARY","SUP","TABLE","TBODY","TD","TEXTAREA","TFOOT","TH","THEAD","TIME","TR","TRACK","TT","U","UL","VAR","VIDEO","WBR"],null)},"cz","$get$cz",function(){return P.bC()},"cJ","$get$cJ",function(){return P.eG(self)},"cx","$get$cx",function(){return H.cK("_$dart_dartObject")},"cC","$get$cC",function(){return function DartObject(a){this.o=a}},"Q","$get$Q",function(){return W.kQ().devicePixelRatio},"a5","$get$a5",function(){var z=$.$get$Q()
if(typeof z!=="number")return H.d(z)
return 80*z},"n","$get$n",function(){var z=$.$get$Q()
if(typeof z!=="number")return H.d(z)
return 34*z},"M","$get$M",function(){var z=$.$get$Q()
if(typeof z!=="number")return H.d(z)
return 10*z},"ap","$get$ap",function(){var z=$.$get$Q()
if(typeof z!=="number")return H.d(z)
return 25*z},"bv","$get$bv",function(){var z=$.$get$Q()
if(typeof z!=="number")return H.d(z)
return 10*z},"aM","$get$aM",function(){return P.bC()}])
I=I.$finishIsolateConstructor(I)
$=new I()
init.metadata=[null,"e","value","_","error","stackTrace","invocation","object","x","data","element","attributeName","context","o","canvasId","sender","closure","isolate","numberOfArguments","arg1","arg2","arg3","arg4","each","arg","time","attr","callback","captureThis","self","arguments","jsonString","language"]
init.types=[{func:1,args:[,]},{func:1,v:true},{func:1},{func:1,v:true,args:[P.e],opt:[P.bl]},{func:1,v:true,args:[{func:1,v:true}]},{func:1,args:[,,]},{func:1,ret:P.p,args:[P.r]},{func:1,ret:P.cH,args:[W.aq,P.p,P.p,W.cy]},{func:1,args:[P.p,,]},{func:1,args:[,P.p]},{func:1,args:[P.p]},{func:1,args:[{func:1,v:true}]},{func:1,args:[,],opt:[,]},{func:1,v:true,args:[,P.bl]},{func:1,args:[P.bm,,]},{func:1,v:true,args:[W.u,W.u]},{func:1,v:true,args:[P.e]},{func:1,ret:P.r,args:[P.p]},{func:1,ret:P.ad,args:[P.p]},{func:1,ret:P.e,args:[,]},{func:1,v:true,args:[P.p,P.p]},{func:1,ret:P.p,args:[P.p,P.p]}]
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
if(x==y)H.kO(d||a)
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
Isolate.az=a.az
Isolate.K=a.K
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
if(typeof dartMainRunner==="function")dartMainRunner(function(b){H.eZ(U.eV(),b)},[])
else (function(b){H.eZ(U.eV(),b)})([])})})()
/*
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




  _relayCallback : function(canvasId) {
    if (canvasId in NetTango._callbacks) {
      NetTango._callbacks[canvasId](canvasId);
    }
  },

  _callbacks : { }
}
