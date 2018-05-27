//
//  GLBaseViewController.m
//  OpenglKit
//
//  Created by AK on 2017/8/19.
//  Copyright © 2017年 yoyo. All rights reserved.
//

#import "GLBaseViewController.h"

@interface GLBaseViewController ()
{
}

@property(strong, nonatomic) EAGLContext *context;
@property(assign, nonatomic) GLuint shaderProgram;
@end

@implementation GLBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupContext];
    [self setupShader];
}

#pragma mark - Setup Context
- (void)setupContext
{
    // 使用OpenGL ES2, ES2之后都采用Shader来管理渲染管线
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context)
    {
        NSLog(@"Failed to create ES context");
    }

    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark - Update Delegate

- (void)update
{
    // 距离上一次调用update过了多长时间，比如一个游戏物体速度是3m/s,那么每一次调用update，
    // 他就会行走3m/s * deltaTime，这样做就可以让游戏物体的行走实际速度与update调用频次无关
    // NSTimeInterval deltaTime = self.timeSinceLastUpdate;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // 设置了清空缓冲区使用的颜色
    glClearColor(0.5, 0.5, 0.5, 0);
    // 表示只清空缓冲区的颜色部分。后续用到深度缓冲区时，还得将深度缓存一起Clear掉
    glClear(GL_COLOR_BUFFER_BIT);

    // 使用fragment.glsl 和 vertex.glsl中的shader
    glUseProgram(self.shaderProgram);

    [self drawTriangle];
}

#pragma mark - Prepare Shaders
bool createProgram(const char *vertexShader, const char *fragmentShader, GLuint *pProgram)
{
    GLuint program, vertShader, fragShader;
    // Create shader program.
    program = glCreateProgram();

    const GLchar *vssource = (GLchar *)vertexShader;
    const GLchar *fssource = (GLchar *)fragmentShader;

    if (!compileShader(&vertShader, GL_VERTEX_SHADER, vssource))
    {
        printf("Failed to compile vertex shader");
        return false;
    }

    if (!compileShader(&fragShader, GL_FRAGMENT_SHADER, fssource))
    {
        printf("Failed to compile fragment shader");
        return false;
    }

    // Attach vertex shader to program.
    glAttachShader(program, vertShader);

    // Attach fragment shader to program.
    glAttachShader(program, fragShader);

    // Link program.
    if (!linkProgram(program))
    {
        printf("Failed to link program: %d", program);

        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        return false;
    }

    // Release vertex and fragment shaders.
    if (vertShader)
    {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader)
    {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }

    *pProgram = program;
    printf("Effect build success => %d \n", program);
    return true;
}

bool compileShader(GLuint *shader, GLenum type, const GLchar *source)
{
    GLint status;

    if (!source)
    {
        printf("Failed to load vertex shader");
        return false;
    }

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);

    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);

#if Debug
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        printf("Shader compile log:\n%s", log);
        printf("Shader: \n %s\n", source);
        free(log);
    }
#endif

    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return false;
    }

    return true;
}

bool linkProgram(GLuint prog)
{
    GLint status;
    glLinkProgram(prog);

#if Debug
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program link log:\n%s", log);
        free(log);
    }
#endif

    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        return false;
    }

    return true;
}

bool validateProgram(GLuint prog)
{
    GLint logLength, status;

    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program validate log:\n%s", log);
        free(log);
    }

    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
    {
        return false;
    }

    return true;
}

- (void)setupShader
{
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"vertex" ofType:@"glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"fragment" ofType:@"glsl"];
    NSString *vertexShaderContent =
        [NSString stringWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:nil];
    NSString *fragmentShaderContent =
        [NSString stringWithContentsOfFile:fragmentShaderPath encoding:NSUTF8StringEncoding error:nil];
    GLuint program;
    createProgram(vertexShaderContent.UTF8String, fragmentShaderContent.UTF8String, &program);
    self.shaderProgram = program;
}

//画一个三角形
- (void)drawTriangle
{
    

    //第一个三角形
    {
        static GLfloat triangleData[18] = {
            0+0.1,     0.5f+0.1,  1, 215./255., 0, 1,  // x, y, z, r, g, b,每一行存储一个点的信息，位置和颜色
            -0.5f+0.1, -0.5f+0.1, 1, 215./255., 0, 1,
            0.5f+0.1, -0.5f+0.1, 1, 215./255., 0, 1,
        };

        GLuint positionAttribLocation = glGetAttribLocation(self.shaderProgram, "position");
        glEnableVertexAttribArray(positionAttribLocation);
        GLuint colorAttribLocation = glGetAttribLocation(self.shaderProgram, "color");
        glEnableVertexAttribArray(colorAttribLocation);
        glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)triangleData);
        glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat),
                              (char *)triangleData + 3 * sizeof(GLfloat));

        glDrawArrays(GL_TRIANGLES, 0, 3);
    }
    
    //画第二个三角形
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA_SATURATE, GL_DST_COLOR);

    static GLfloat triangleData[18] = {
        0,     0.5f,  1, 1, 1, 1,  // x, y, z, r, g, b,每一行存储一个点的信息，位置和颜色
        -0.5f, -0.5f, 1, 1, 1, 1,
        0.5f, -0.5f, 1, 1, 1, 1,
    };

    //    首先通过glEnableVertexAttribArray激活shader中的两个属性。glGetAttribLocation是为了获取shader中某个属性的位置。这是shader与OpenGL约定的数据互通方式
    // 启用Shader中的两个属性
    // attribute vec4 position;
    // attribute vec4 color;
    GLuint positionAttribLocation = glGetAttribLocation(self.shaderProgram, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    GLuint colorAttribLocation = glGetAttribLocation(self.shaderProgram, "color");
    glEnableVertexAttribArray(colorAttribLocation);

    // 为shader中的position和color赋值
    // glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid*
    // ptr)
    // indx: 上面Get到的Location
    // size: 有几个类型为type的数据，比如位置有x,y,z三个GLfloat元素，值就为3
    // type: 一般就是数组里元素数据的类型
    // normalized: 暂时用不上
    // stride: 每一个点包含几个byte，本例中就是6个GLfloat，x,y,z,r,g,b
    // ptr: 数据开始的指针，位置就是从头开始，颜色则跳过3个GLFloat的大小
    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)triangleData);
    glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat),
                          (char *)triangleData + 3 * sizeof(GLfloat));

    glDrawArrays(GL_TRIANGLES, 0, 3);

    
    glDisable(GL_BLEND);
}

@end
