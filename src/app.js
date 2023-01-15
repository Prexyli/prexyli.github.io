import * as THREE from './utils/three.module.js';
import { OrbitControls } from './utils/OrbitControls.js';
import { color, GUI } from './utils/dat.gui.module.js';
import Stats from './utils/stats.module.js'

//Three.js shaders
let planetVertexShader,
    planetFragmentShader,
    atmoVertexShader,
    atmoFragmentShader,
    ringVertexShader,
    ringFragmentShader;

//Three.js meshes
let ringMesh, atmosphere;

//Loaders
const fileloader = new THREE.FileLoader();
const textureLoader = new THREE.TextureLoader();

var controls;
var camera, scene, renderer;
const skyboxImage = 'space';
var planetMaterial, atmosphereMaterial, ringMaterial;

//Adding the stats component
const stats = Stats();
document.body.appendChild(stats.dom)

let numShaders = 6;
loadShaders();

var guiControls = new (function () {
    this.color1 = "#FFFFFF";
    this.color2 = "#142E80";
    this.color3 = "#89AA5F";
    this.color4 = "#A35133";
    this.color5 = "#14B0B0";
    this.atmosphereColor = "#14B0B0";
    this.autorotate = false;
    this.speed = 0.01;
    this.ring = 3.2;
    this.ringColor1 = "#14B0B0";
    this.ringColor2 = "#89AA5F";
    this.ringback = true;
    this.qMult = 1.7;
    this.rMult = 3.0;
    this.vMult = 3.5;
    this.amplitude = 0.5;
    this.fbmfunc = true;
    this.ringshow = true;
    this.atmosphereshow = false;
})

function loadShaders() {
    fileloader.load("./src/shaders/planetVert.glsl", (data) => {
        planetVertexShader = data;
        confirmLoad()
        console.log("Vertex loaded");
    }, null, (error) => {
        console.log('ShaderLoadError', error);
    });

    fileloader.load("./src/shaders/planetFrag.glsl", (data) => {
        planetFragmentShader = data;
        confirmLoad()
        console.log("Fragment loaded");
    }, null, (error) => {
        console.log('ShaderLoadError', error);
        
    });
    fileloader.load("./src/shaders/ringVert.glsl", (data) => {
        ringVertexShader = data;
        confirmLoad()
        console.log("Ring Vertex loaded");
    }, null, (error) => {
        console.log('ShaderLoadError', error);
        
    });
    fileloader.load("./src/shaders/ringFrag.glsl", (data) => {
        ringFragmentShader = data;
        confirmLoad()
        console.log("Ring Fragment loaded");
    }, null, (error) => {
        console.log('ShaderLoadError', error);
        
    });
    fileloader.load("./src/shaders/atmoVert.glsl", (data) => {
        atmoVertexShader = data;
        confirmLoad()
        console.log("Atmo Vertex loaded");
    }, null, (error) => {
        console.log('ShaderLoadError', error);
        
    });
    fileloader.load("./src/shaders/atmoFrag.glsl", (data) => {
        atmoFragmentShader = data;
        confirmLoad()
        console.log("Atmo Fragment loaded");
    }, null, (error) => {
        console.log('ShaderLoadError', error);
        
    });
    
    
    //Check if all shaders have loaded
    function confirmLoad() {
        numShaders -= 1;
        //If all Shaders have loaded run program
        if(numShaders === 0) {
            intialize();
            animate();
        }
    }
}

// SKYBOX MATERIAL LOADER
// Code for skybox was inspired by https://codinhood.com/post/create-skybox-with-threejs
function createMaterialArray(filename) {
    const skyboxImagepaths = createPathStrings(filename);
    const materialArray = skyboxImagepaths.map(image => {
        let texture = new THREE.TextureLoader().load(image);
    
        return new THREE.MeshBasicMaterial({ map: texture, side: THREE.BackSide });
    });
    return materialArray;
}

function createPathStrings(filename) {
    const basePath = "../Textures/";
    const baseFilename = basePath + filename;
    const fileType = ".png";
    const sides = ["ft", "bk", "up", "dn", "rt", "lf"];
    const pathStings = sides.map(side => {
        return baseFilename + "_" + side + fileType;
    });
    
    return pathStings;
}
//

function onWindowResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
}

function intialize(){
    //Renderer
    renderer = new THREE.WebGLRenderer( {antialias: true});
    renderer.setSize( window.innerWidth, window.innerHeight );
    document.body.appendChild( renderer.domElement );

    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );
    camera.position.z = 5;

    //Orbit Controls
    controls = new OrbitControls(camera, renderer.domElement);
    controls.enabled = true;
    controls.minDistance = 2;
    controls.maxDistance = 100;
    controls.autoRotate = false;
    controls.autoRotateSpeed = 1.0;

    //GUI definitions
    const gui = new GUI({ width: 350 });
    var planetFolder = gui.addFolder("Planet Control");
    planetFolder.add(guiControls, "qMult", 0.0, 10.0);
    planetFolder.add(guiControls, "rMult", 0.0, 10.0);
    planetFolder.add(guiControls, "vMult", 0.0, 10.0);
    planetFolder.add(guiControls, "amplitude", 0.0, 1.5);
    planetFolder.add(guiControls, "fbmfunc");
    var folder = gui.addFolder("Colors");
    folder.addColor(guiControls, 'color1');
    folder.addColor(guiControls, 'color2');
    folder.addColor(guiControls, 'color3');
    folder.addColor(guiControls, 'color4');
    folder.addColor(guiControls, 'color5');
    folder.addColor(guiControls, 'atmosphereColor');
    var ringFolder = gui.addFolder("Rings");
    ringFolder.add(guiControls, "ring", 1.0, 6.0);
    ringFolder.addColor(guiControls, 'ringColor1');
    ringFolder.addColor(guiControls, 'ringColor2');
    ringFolder.add(guiControls,"ringback");
    gui.add(guiControls, "ringshow");
    gui.add(guiControls, "atmosphereshow");
    gui.add(guiControls, "autorotate");
    gui.add(guiControls, "speed", 0.001, 1.1);
    
    //Adding a Sphere
    const geometry = new THREE.SphereGeometry(1, 100, 100);
    planetMaterial = new THREE.RawShaderMaterial({
        uniforms: {
            time: {value: 1.0},
            color1: {value: new THREE.Color(guiControls.color1)},
            color2: { value: new THREE.Color(guiControls.color2)},
            color3: { value: new THREE.Color(guiControls.color3)},
            color4: { value: new THREE.Color(guiControls.color4)},
            color5: { value: new THREE.Color(guiControls.color5)},
            qMult: { value: guiControls.qMult},
            rMult: { value: guiControls.rMult},
            vMult: { value: guiControls.vMult},
            amplitude: { value: guiControls.amplitude },
            fbmfunc: { value: guiControls.fbmfunc }
        },
         vertexShader: planetVertexShader,
         fragmentShader: planetFragmentShader,
    });
    const planet = new THREE.Mesh( geometry, planetMaterial );
    scene.add( planet );

    //Sun
    const sungeo = new THREE.SphereGeometry(1, 10, 10);
    const sunMaterial = new THREE.MeshStandardMaterial({
        color: 0xFFFFFF,
        emissive: 0xFFFFFF
    });
    const sun = new THREE.Mesh(sungeo, sunMaterial);
    sun.position.x = 100;
    sun.position.y = 100;
    sun.position.z = 100;
    scene.add( sun );

    //Atmosphere
    console.log(sun.position);
    const atmosphereGeometry = new THREE.SphereGeometry(1.1, 100, 100);
    atmosphereMaterial = new THREE.RawShaderMaterial({
        uniforms: {
            atmoColor: { value: new THREE.Color(guiControls.atmosphereColor)} 
        },
         vertexShader: atmoVertexShader,
         fragmentShader: atmoFragmentShader,
         blending: THREE.AdditiveBlending,
         transparent: true,
         side: THREE.BackSide,
         depthWrite: false
    });
    atmosphere = new THREE.Mesh( atmosphereGeometry, atmosphereMaterial );
    scene.add( atmosphere );

    //Ring
    const ringGeometry = new THREE.RingGeometry(1.5, 2.5, 64);
    ringMaterial = new THREE.ShaderMaterial({
        uniforms: {
            time: {value: 1.0},
            ringValue: {value: guiControls.ring},
            color1: {value: new THREE.Color(guiControls.ringColor1)},
            color2: { value: new THREE.Color(guiControls.ringColor2)},
        },
        vertexShader: ringVertexShader,
        fragmentShader: ringFragmentShader,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide,
        transparent: true,
    });
    ringMesh = new THREE.Mesh(ringGeometry, ringMaterial);
    ringMesh.lookAt( new THREE.Vector3(1.0,1.0,1.0));
    scene.add( ringMesh);

    //Skybox
    const materialArray = createMaterialArray(skyboxImage);
    const skyboxGeometry = new THREE.BoxGeometry(1200,1200,1200);
    const skybox = new THREE.Mesh(skyboxGeometry,materialArray);
    scene.add(skybox);


    window.addEventListener('resize', onWindowResize, false);
}

function animate() {
    const planetGeometry = scene.children[0];

    updateGuiControls();

    controls.update();
    requestAnimationFrame( animate );
    renderer.render(scene, camera);
    stats.update();
}

//GUI controls that will be updateded every frame
function updateGuiControls(){
    planetMaterial.uniforms.time.value += guiControls.speed;
    ringMaterial.uniforms.time.value += guiControls.speed;
    controls.autoRotate = guiControls.autorotate;
    planetMaterial.uniforms.qMult = { value: guiControls.qMult};
    planetMaterial.uniforms.rMult = { value: guiControls.rMult};
    planetMaterial.uniforms.vMult = { value: guiControls.vMult};
    planetMaterial.uniforms.amplitude = { value: guiControls.amplitude};
    planetMaterial.uniforms.fbmfunc = { value: guiControls.fbmfunc};
    planetMaterial.uniforms.color1 = { value: new THREE.Color(guiControls.color1)};
    planetMaterial.uniforms.color2 = { value: new THREE.Color(guiControls.color2)};
    planetMaterial.uniforms.color3 = { value: new THREE.Color(guiControls.color3)};
    planetMaterial.uniforms.color4 = { value: new THREE.Color(guiControls.color4)};
    planetMaterial.uniforms.color5 = { value: new THREE.Color(guiControls.color5)};
    atmosphereMaterial.uniforms.atmoColor = { value: new THREE.Color(guiControls.atmosphereColor)};
    ringMaterial.uniforms.color1 = { value: new THREE.Color(guiControls.ringColor1)};
    ringMaterial.uniforms.color2 = { value: new THREE.Color(guiControls.ringColor2)};
    ringMaterial.uniforms.ringValue = { value: guiControls.ring}
    ringMaterial.side = guiControls.ringback ? THREE.DoubleSide : THREE.FrontSide;
    ringMesh.visible = guiControls.ringshow;
    atmosphere.visible = guiControls.atmosphereshow;
}