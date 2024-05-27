---
title: React.js
category:
  - Full Stack
  - React
tag:
  - Full Stack
abbrlink: 9de
date: 2024-05-01 12:42:10
keywords:
description:
---

## 1. DOM
The Document Object Model (DOM) is the data representation of the objects that comprise the structure and content of a document on the web.
A web page is a document that can be either displayed in the browser window or as the HTML source. In both cases, it is the same document but the Document Object Model (DOM) representation allows it to be manipulated. As an object-oriented representation of the web page, it can be modified with a scripting language such as JavaScript.
The DOM is not part of the JavaScript language, but is instead a Web API used to build websites.


## 2. Virtual DOM
* Virtual DOM 并不是真实的 DOM，它跟原生 DOM 本质上没什么关系
* 本质上 Virtual DOM 对应的是一个 JavaScript 对象，它描述的是视图和应用状态之间的一种映射关系，是某一时刻真实 DOM 状态的内存映射。
* 在视图显示方面，Virtual DOM 对象的节点跟真实 DOM Tree 每个位置的属性一一对应
* 我们不再需要直接的操作 DOM，只需要关注应用的状态即可，操作 DOM 的事情有框架替我们做了

### 2.1 Why use virtual DOM
Manipulating the DOM is slow. Manipulating the virtual DOM is much faster because nothing gets drawn onscreen.
* 操作 DOM 时，任何DOM API调用都要先将JS数据结构转为DOM数据结构，再挂起JS引擎线程并启动渲染引擎线程，执行过后再把可能的返回值反转数据结构，重启 JS 引擎继续执行。这种两个线程之间的上下文切换势必会很耗性能. 另外很多 DOM API 的读写都涉及页面布局的 重绘（repaint）和回流（reflow），这会更加的耗费性能。
* React相对于直接操作原生DOM最大的优势在于 **batching** 和 **diff**。为了尽量减少不必要的 DOM 操作， Virtual DOM 在执行 DOM 的更新操作后，不会直接操作真实 DOM，而是根据当前应用状态的数据，生成一个全新的 Virtual DOM，然后跟上一次生成 的 Virtual DOM 去 diff，得到一个 Patch，这样就可以找到变化了的 DOM 节点，只对变化的部分进行 DOM 更新，而不是重新渲染整个 DOM 树，这个过程就是 diff

### 2.2 Pros of Virtual DOM
* No need to directly manipulate the DOM
* improve rendering efficiency by reducing the number of page renders
* provides better cross-platform capabilities because the virtual DOM is based on JavaScript objects rather than relying on specific platform environments. Therefore, it can be used on other platforms, such as Node.js

The React element is actually just a regular JavaScript object, which is used to describe a DOM node or an instance of a component. When we use the Button component in JSX, it's like calling the `React.createElement()` method to instantiate the component. Since components can reference other components, when we build a component, it forms a tree-like structure of components. React recursively converts it into React elements, layer by layer. When encountering a type that starts with a capital letter, React knows it's a custom component element, then it executes the `render` method of the component or executes the function of that component (depending on whether it's a class component or a function component), finally returning an element.


## 3. React Component
* React elements are the smallest building blocks of React applications. They are plain objects that describe the structure and content of the user interface. Elements are immutable, meaning once created, they cannot be changed.
* React components are more complex constructs that contain multiple elements and other components. They encapsulate the structure, behavior, and state of a component.

In summary, React components are reusable pieces of code that encapsulate the structure, behavior, and state of a UI element. React elements are the smallest building blocks of a React application and are created by calling the React.createElement() function.

Types of component:
* Stateless component: The most basic form of a component, without any state. consists of properties (props) along with a rendering function (render).
* Stateful component: contains state, state changes when there's any new event or parameter. Stateful components typically come with lifecycles to trigger state updates at different moments. Different scenarios requiring different states and lifecycles.


## 4. Bubbling and Capturing
The standard DOM Events describes 3 phases of event propagation:
1. Capturing: the event goes down to the element.
2. Target: the event reached the target element.
3. Bubbling: the event bubbles up from the element.

Capturing: this phase was invisible unless set the handler `capture` option to `true`. (For example: `HTML -> BODY -> FORM -> DIV -> P`)
Bubbling: When an event happens on an element, it first runs the handlers on it, then on its parent, then all the way up on other ancestors. Almost all events bubble. (For example: `P -> DIV -> FORM -> BODY -> HTML`)


## 5. Event
* event.target: the deepest element that originated the event
* event.currentTarget (this): the current element that handles the event (the one that has the handler on it)
* event.eventPhase: the current phase (capturing=1, target=2, bubbling=3)

Stop Events:
* event.stopPropagation(): prevents further propagation of the current event in the **capturing** and **bubbling** phases
* event.stopImmediatePropagation(): prevents other listeners of the same event from being called
* event.preventDefault(): don't take default action if the event doesn't get handled


## 6. Fragments
A common pattern in React is for a component to return multiple elements. Fragments let you group a list of children without adding extra nodes to the DOM. `key` is the only attribute that can be passed to Fragment. 


## 7. createPortal
Allow developer to render an element in another location in the DOM: This lets position or style an element correctly. A typical use case for portals is when a parent component has an `overflow: hidden` or `z-index` style.
```js
/**
 * params:
 *    * children: Anything that can be rendered with React (JSX, Fragment, string, number 
 *      or an array)
 *    * domNode: a DOM node (returned by document.getElementById)
 *    * key (optional): 
 */
createPortal(children, domNode, key?) 
```

Event bubbling and context work as normal since the portal still exists in the React tree regardless of position in the DOM tree.


## 8. Error Boundaries
Error boundaries are React components that catch JavaScript errors in their child component tree, log those errors, and display a fallback UI instead of the component tree that crashed.
A class component becomes an error boundary if it defines either (or both) of the lifecycle methods static `getDerivedStateFromError()` or `componentDidCatch()`.
`try / catch` only works for imperative code; However, React components are declarative. Error boundaries preserve the declarative nature of React, and behave as you would expect.
Error boundaries don't catch the following errors:
* Event handlers (learn more)
* Asynchronous code (e.g. setTimeout or requestAnimationFrame callbacks)
* Server side rendering
* Errors thrown in the error boundary itself 


## 9. Context
Context provides a way to pass data through the component tree without having to pass props down manually at every level.
In a typical React application, data is passed top-down (parent to child) via props, but such usage can be cumbersome for certain types of props (e.g. locale preference, UI theme) that are required by many components within an application. Context provides a way to share values like these between components without having to explicitly pass a prop through every level of the tree.


## 10. Render Props
Render prop refers to a technique for sharing code between React components using a prop whose value is a function. 
* Problem: Components are the primary unit of code reuse in React, but it's not always obvious how to share the state or behavior that one component encapsulates to other components that need that same state.
* Solution: render prop is a function prop that a component uses to know what to render. For example, component A wants to pass its state to component B: In A, call `this.props.render(this.state)`; when use A, pass function with B to A `<A render={ info => (<B info={info} />) }/>`; So B can use A's state directly, `const info = this.props.info;`
* Render props have been replaced by custom Hooks


## 11. Refs and the DOM
React automatically updates the DOM to match the render output, so components don't need to manipulate it.
However, sometimes you might need access to the DOM elements managed by React:
* Managing focus, text selection, or media playback.
* Measure its size and position
* Triggering imperative animations (ex. scroll).
* Integrating with third-party DOM libraries.

Refs provide a way to access DOM nodes or React elements. Accessing Refs:
* When the `ref` attribute is used on an HTML element, the `ref` created in the constructor with `React.createRef()` receives the underlying DOM element as its `current` property.
* When the `ref` attribute is used on a **class** component, the `ref` object receives the mounted instance of the component as its `current` property.

### 11.1 Pass ref to component
When you put a ref on a built-in component like `<input />`, React will set current property to the corresponding DOM node:
```js
import { useRef } from 'react';

const myRef = useRef(null);
<div ref={myRef}>

// You can use any browser APIs, for example:
myRef.current.scrollIntoView();
```
When you put a ref on your own component, by default you will get `null`. Instead, your component should forwards the ref from props to one of its built-in component.

### 11.2 Ref Callback 
Since hooks must only be called at the top-level of component. You can't call `useRef` in a loop, in a condition, or inside a `map()` call. The solution is to pass a function to the `ref` attribute. React will call your `ref callback` with the DOM node when it’s time to set the ref, and with null when it’s time to clear it.


## 12. Hooks
Problem:
* hard to reuse stateful logic between components: render props and higher-order components needs to restructure your components, and causes wrapper hell. Hooks allow you to reuse stateful logic without changing your component hierarchy.
* Complex components become hard to understand: Each lifecycle method often contains a mix of unrelated logic. For example, components might perform some data fetching in `componentDidMount` and `componentDidUpdate`. However, the same `componentDidMount` method might also contain some unrelated logic that sets up event listeners, with cleanup performed in `componentWillUnmount`. Hooks split one component into smaller functions based on what pieces are related (such as setting up a subscription or fetching data)

### 12.2 State Hook
```js
/**
 * params:
 *    initialState: The value you want the state to be initially
 * return:
 *    state: During the first render, it will match the initialState you have passed
 *    setState: lets you update the state to a different value and trigger a re-render
 */
const [state, setState] = useState(initialState);
```
Returns a stateful value, and a function to update it(`setState`). During the initial render, the returned state (`state`) is the same as the value passed as the first argument (`initialState`).
The `setState` function is used to update the state:
* accept a new state value and enqueues a re-render of the component.
* accept a function which will receive the previous value, and return an updated value

Others:
* Lazy initial state: If the initial state is the result of an expensive computation, you may provide a function instead, which will be executed only on the initial render.
* If you update a state to the same value as the current state, React will not re-render the children or trigger effects

### 12.3 Effect Hook
In React class components, the `render` method itself shouldn't cause side effects. We typically want to perform our effects after React has updated the DOM. This is why React class puts side effects into `componentDidMount` and `componentDidUpdate`.
Problem:
* `componentDidMount` and `componentDidUpdate` may have the same code
* `componentDidMount` and `componentWillUnmount` need to mirror each other

```js
/**
 * params:
 *    * setup: When component is added to the DOM, React will run your setup function. After
 *      every re-render with changed dependencies, React will first run the cleanup function
 *      with old value (if provided), then run the setup function with the new values.
 *    * dependencies (optional): The list of all reactive values referenced inside of the
 *      setup code. Reactive values include props, state, and all the variables and 
 *      functions declared directly inside your component body. 
 */
useEffect(setup, dependencies?);
```
So we can place all code related with re-render in `useEffect`, instead of three places:
* Skip second argument: `useEffect` runs both after the first render and after every update. Instead of thinking in terms of "mounting" and "updating", you might find it easier to think that effects happen "after render".
* Pass an array as second argument: React will re-run the effect if one of values in array is updated, usually using props and state
* empty array as second argument: React will only run the effect when mount and unmount component

### 12.4 Memo Hook
`useMemo` will only recompute the memoized value when one of the dependencies has changed. `useMemo` is a tool for optimizing rendering performance.
```js
/**
 * params:
 *    * calculateValue: The function calculating the value that you want to cache. It should
 *      take no arguments, and should return a value of any type. React will call your
 *      function during the initial render. On next renders, React will return the same 
 *      value again if the dependencies have not changed since the last render.
 *    * dependencies: The list of all reactive values. Reactive values include props, state,
 *      and all the variables and functions declared directly inside your component body.
 */
const cachedValue = useMemo(calculateValue, dependencies)
```
Usage:
* Skipping expensive recalculations: For example, component A has two child components, B and C. When A' state changes, triggering a re-render. At this point, both B and C also re-render. By employing `useMemo`, only when the props used by B change, B will be re-rendered, while C will remain unaffected.
* Skipping re-rendering of components: For example, component A passes prop to its child component. By default, when a component re-renders, React re-renders all of its children recursively. If re-render is slow, you can put calculation in `useMemo` to ensure that it has the same value between the re-renders (until dependencies change).

### 12.5 Context Hook
```js
/**
 * params:
 *    * SomeContext: The context that you’ve previously created with React.createContext
 * return: the context value for the calling component
 */
const value = useContext(SomeContext);
```
The current context value is determined by the `value` prop of the nearest `<MyContext.Provider>` above the calling component in the tree.
When the nearest `<MyContext.Provider>` above the component updates, this Hook will trigger a rerender with the latest context `value` passed to that `MyContext` provider.

Usage:
* Passing data deeply into the tree
* Updating data passed via context: pass the current state as the context value to the provider.
* Specifying a fallback default value
* Overriding context for a part of the tree
* Optimizing re-renders when passing objects and functions

### 12.6 Ref Hook
`useRef` is a React Hook that lets you reference a value that's not needed for rendering.
```js
/**
 * params:
 *    initialValue: The value you want the ref object's current property to be initially.
 *    current: Initially, it's set to the initialValue you have passed
 * return: returns an object, will persist for the full lifetime of the component.
 */
const ref = useRef(initialValue)
```
Differences between refs and other variable:
* Regular variable will reset on every render; ref will be the same between each re-renders
* chaninge state variable will trigger a re-render; changing ref does not trigger a re-render
* outside variable are shared by all components; ref is local to each copy of your component

Caveats: you can modify and update the `current` value outside of the rendering process, but shouldn't read or write the `current` value during rendering.

When to use refs:
* Storing timeout ID (setTimeout)
* Storing and manipulating DOM elements
* Storing other objects that aren’t necessary to calculate the JSX

### 12.7 Reducer Hook
`useReducer` is an alternative to `useState`. Accepts a reducer of type `(state, action) => newState`, and returns the current state paired with a `dispatch` method.
```js
const [state, dispatch] = useReducer(reducer, initialArg, init);
```

`useReducer` is preferable to `useState` when you have complex state logic that involves multiple sub-values or when the next state depends on the previous one. 
```js
const initialState = {count: 0};

function  (state, action) {
  switch (action.type) {
    case 'increment':
      return {count: state.count + 1};
    case 'decrement':
      return {count: state.count - 1};
    default:
      throw new Error();
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, initialState);
  return (
    <>
      Count: {state.count}
      <button onClick={() => dispatch({type: 'decrement'})}>-</button>
      <button onClick={() => dispatch({type: 'increment'})}>+</button>
    </>
  );
}
```

### 12.8 Layout Hook
`useLayoutEffect` is a version of `useEffect` that fires before the browser repaints the screen.
```js
/**
 * params:
 *    setup: The function with your Effect's logic.
 *    dependencies (optional): The list of all reactive values referenced inside of the `setup` code.
 */
useLayoutEffect(setup, dependencies?)
```
`useLayoutEffect` vs `useEffect`:
* `useLayoutEffect` blocks the browser from repainting
* `useEffect` does not block the browser

Caveats:
* `useLayoutEffect` is a Hook, so you can only call it at the top level of your component or your own Hooks
* Effects only run on the client. They don’t run during server rendering.

Usage: Measuring layout before the browser repaints the screen


## 13. Strict Mode
`StrictMode` is a tool for highlighting potential problems:
* Identify unsafe lifecycles: certain legacy lifecycle methods(e.g. `componentWillMount`, `componentWillReceiveProps`, `componentWillUpdate`) are unsafe, if your application uses third party libraries, it can be difficult to ensure that these lifecycles aren't being used
* Warning about legacy string ref API usage
* Warning about deprecated findDOMNode usage: you can attach a ref directly to a DOM node
* Detecting unexpected side effects: 
* Detecting legacy context API
* Ensuring reusable state


## 14. Rules of React
* Components and Hooks must be pure: A component or hook should follow the rules:
  * Idempotent: always get the same result when run it with the same inputs (props, state, context amd hook input)
  * No side effects in render: Code with side effects should run in event handler or useEffect
  * Does not change non-local values
* React calls Components and Hooks:
  * Never call component functions directly
  ```js
  function BlogPost() {
    return <Layout>{Article()}</Layout>; // Wrong: Never call them directly
  }
  ```
  * Never pass around Hooks as regular values
* Only call Hooks at the top level
* Only call Hooks from React functions