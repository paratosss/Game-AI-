shader_type sky;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void sky(){
 float h=clamp(EYEDIR.y,0.,1.);
 vec3 blue=mix(vec3(.58,.68,.73),vec3(.21,.39,.57),pow(h,.45));
 vec2 p=EYEDIR.xz/max(.18,EYEDIR.y)*.85;
 float n=noise(p)*.50+noise(p*2.1)*.28+noise(p*4.7)*.14+noise(p*9.2)*.08;
 float cloud=smoothstep(.58,.75,n)*smoothstep(.07,.25,h);
 COLOR=mix(blue,vec3(.84,.86,.85),cloud*.63);
 if(EYEDIR.y<0.){COLOR=mix(vec3(.30,.34,.27),vec3(.53,.60,.61),pow(clamp(1.+EYEDIR.y,0.,1.),6.));}
}
