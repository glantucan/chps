package napetests;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.Lib;
import nape.constraint.PivotJoint;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;
import nape.util.Debug;
import nape.util.ShapeDebug;

/**
 * ...
 * @author Glantucan
 */
class HelloWorld
{
	var stage:Stage;
	var space:Space;
	var debug:Debug;
	var prevTime:Int = 0;
	var curTime:Int;
	var handJoint:PivotJoint;
	var prevBodyCenter:Vec2;
	var debugPrevPos_sp:Sprite;
	var chapaBody:Body;
	
	public function new(stage:Stage) 
	{
		this.stage = stage;
		space =  new Space();
		debug =  new ShapeDebug(stage.stageWidth, stage.stageHeight, stage.color);
		stage.addChild(debug.display);
	}
	
	public function start():Void
	{
		var groundShape:Polygon =  new Polygon(Polygon.rect(0, 0, stage.stageWidth, stage.stageHeight));
		groundShape.fluidEnabled = true;
		groundShape.fluidProperties.viscosity = 2;
		var groundBody = new Body(BodyType.STATIC);
		groundBody.shapes.push(groundShape);
		space.bodies.push(groundBody);
		
		var chapaShape:Circle = new Circle(10); //, new Vec2(5, 0)
		chapaShape.material = Material.steel();
		
		chapaBody = new Body();
		chapaBody.shapes.push(chapaShape);
		chapaBody.position = new Vec2(stage.stageWidth / 2, stage.stageHeight / 2);
		chapaBody.velocity = new Vec2(3, 0);
		chapaBody.allowRotation = false;
		space.bodies.push(chapaBody);
		
		handJoint = new PivotJoint(space.world, null, Vec2.weak(), Vec2.weak());
		handJoint.space = space;
		handJoint.active = false;
		// We also define this joint to be 'elastic' by setting
		// its 'stiff' property to false.
		//
		// We could further configure elastic behaviour of this
		// constraint through the 'frequency' and 'damping'
		// properties.
		handJoint.stiff = false;
		
		prevTime = Lib.getTimer();
		stage.addEventListener(Event.ENTER_FRAME, update);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
	}
	
	private function mouseUpHandler(e:MouseEvent):Void 
	{
		
		
		if (debugPrevPos_sp != null && stage.contains(debugPrevPos_sp)) {
			var distance:Float = Vec2.distance(prevBodyCenter, handJoint.body2.position);
			
			var force:Vec2 = Vec2.get(	(prevBodyCenter.x - stage.mouseX) *10 ,
										(prevBodyCenter.y - stage.mouseY) *10);
			trace(prevBodyCenter);
			trace( stage.mouseX,  stage.mouseY);
			trace( e.target.mouseX,  e.target.mouseY);
			trace(force);
			//chapaBody.force = force;
			chapaBody.applyImpulse(force, handJoint.anchor2);
			trace(chapaBody.force);
			stage.removeChild(debugPrevPos_sp);
		}
		handJoint.active = false;
	}
	
	private function mouseDownHandler(e:MouseEvent):Void 
	{
		
		var mousePoint = Vec2.get(stage.mouseX, stage.mouseY);
		
		for (body in space.bodiesUnderPoint(mousePoint)) 
		{
			// Determine the set of Body's which are intersecting mouse point.
			// And search for any 'dynamic' type Body to begin dragging.
			if (!body.isDynamic()) {
				continue;
			}
		 
			// Configure hand joint to drag this body.
			// We initialise the anchor point on this body so that
			// constraint is satisfied.
			//
			// The second argument of worldPointToLocal means we get back
			// a 'weak' Vec2 which will be automatically sent back to object
			// pool when setting the handJoint's anchor2 property.
			handJoint.body2 = body;
			handJoint.anchor2.set(body.worldPointToLocal(mousePoint, true));
			prevBodyCenter = Vec2.get(body.position.x, body.position.y);
			
			if (debugPrevPos_sp == null) {
				debugPrevPos_sp = new Sprite();
				debugPrevPos_sp.graphics.lineStyle(1);
				debugPrevPos_sp.graphics.drawCircle(0, 0, 2);
			}
			stage.addChild(debugPrevPos_sp);
			debugPrevPos_sp.x = prevBodyCenter.x;
			debugPrevPos_sp.y = prevBodyCenter.y;
			// Enable hand joint!
			handJoint.active = true;
			 
			break;
		}
	}
	
	
	function update(e:Event):Void 
	{
		if (handJoint.active) {
			handJoint.anchor1.setxy(stage.mouseX, stage.mouseY);
		}
		
		curTime =  Lib.getTimer();
		var delta:Float = (Lib.getTimer() - prevTime) * .001;
		// We cap this value so that if execution is paused we do
		// not end up trying to simulate 10 minutes at once.
		//trace(delta);
		if (delta > 0.05) {
			delta = 0.05;
		}
		space.step(delta);
		prevTime = curTime;
		
		// Clear the debug display.
		debug.clear();
		// Draw our Space.
		debug.draw(space);
		// Flush draw calls, until this is called nothing will actually be displayed.
		debug.flush();
	}
}